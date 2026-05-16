package colors

import (
	"fmt"
	"image"
	_ "image/jpeg"
	_ "image/png"
	"math"
	"os"
	"sort"
	"strings"
)

type RGB struct {
	R uint8
	G uint8
	B uint8
}

type Palette struct {
	BG     string
	FG     string
	Accent string
	Colors [16]string
}

type bucket struct {
	count int
	rsum  int
	gsum  int
	bsum  int
}

type candidate struct {
	rgb RGB
	h   float64
	w   float64
	l   float64
	s   float64
}

func ExtractFromImage(path string) (Palette, error) {
	f, err := os.Open(path)
	if err != nil {
		return Palette{}, fmt.Errorf("open image: %w", err)
	}
	defer f.Close()

	img, _, err := image.Decode(f)
	if err != nil {
		return Palette{}, fmt.Errorf("decode image: %w", err)
	}

	bounds := img.Bounds()
	w, h := bounds.Dx(), bounds.Dy()
	if w == 0 || h == 0 {
		return Palette{}, fmt.Errorf("invalid image dimensions")
	}

	// Sample the image at a stride to avoid expensive full image scans.
	step := int(math.Max(1, float64(maxInt(w, h))/256.0))
	bins := map[int]*bucket{}

	for y := bounds.Min.Y; y < bounds.Max.Y; y += step {
		for x := bounds.Min.X; x < bounds.Max.X; x += step {
			r, g, b, a := img.At(x, y).RGBA()
			if a == 0 {
				continue
			}
			r8 := uint8(r >> 8)
			g8 := uint8(g >> 8)
			b8 := uint8(b >> 8)

			// 4-bit quantization per channel (4096 buckets total).
			qr := int(r8 >> 4)
			qg := int(g8 >> 4)
			qb := int(b8 >> 4)
			key := (qr << 8) | (qg << 4) | qb
			bk := bins[key]
			if bk == nil {
				bk = &bucket{}
				bins[key] = bk
			}
			bk.count++
			bk.rsum += int(r8)
			bk.gsum += int(g8)
			bk.bsum += int(b8)
		}
	}

	if len(bins) == 0 {
		return Palette{}, fmt.Errorf("no colors found in image")
	}

	cands := make([]candidate, 0, len(bins))
	for _, b := range bins {
		if b.count <= 0 {
			continue
		}
		r := uint8(b.rsum / b.count)
		g := uint8(b.gsum / b.count)
		bl := uint8(b.bsum / b.count)
		h, s, l := rgbToHsl(r, g, bl)
		cands = append(cands, candidate{
			rgb: RGB{R: r, G: g, B: bl},
			h:   h,
			w:   float64(b.count),
			l:   l,
			s:   s,
		})
	}

	if len(cands) == 0 {
		return Palette{}, fmt.Errorf("could not derive palette candidates")
	}

	sort.Slice(cands, func(i, j int) bool {
		return cands[i].w > cands[j].w
	})

	ranked := cands
	if len(ranked) > 96 {
		ranked = ranked[:96]
	}

	bg := chooseBackground(ranked)
	fg := chooseForeground(ranked, bg)
	accents := chooseAccents(ranked, bg, fg)
	base := buildPalette(bg, fg, accents)

	var out [16]string
	for i := 0; i < 16; i++ {
		out[i] = rgbHex(base[i])
	}

	return Palette{
		BG:     rgbHex(bg),
		FG:     rgbHex(fg),
		Accent: rgbHex(base[3]),
		Colors: out,
	}, nil
}

func chooseBackground(cands []candidate) RGB {
	best := cands[0]
	bestScore := -1.0
	for _, c := range cands {
		if c.l > 0.52 {
			continue
		}
		score := c.w * (1.2 - c.l) * (1.1 - c.s*0.35)
		if score > bestScore {
			bestScore = score
			best = c
		}
	}
	if bestScore < 0 {
		best = cands[0]
	}
	bg := clampMinLuma(best.rgb, 0.06)
	if relativeLuminance(bg) > 0.22 {
		bg = blend(bg, RGB{R: 0, G: 0, B: 0}, 0.22)
	}
	return bg
}

func chooseForeground(cands []candidate, bg RGB) RGB {
	best := cands[0]
	bestScore := -1.0
	for _, c := range cands {
		if c.l < 0.48 {
			continue
		}
		contrast := contrastRatio(c.rgb, bg)
		if contrast < 4.2 {
			continue
		}
		score := (c.l * 1.2) + (math.Log(c.w+1) / 7.5)
		if score > bestScore {
			bestScore = score
			best = c
		}
	}
	if bestScore < 0 {
		return RGB{R: 230, G: 230, B: 230}
	}
	fg := clampMaxLuma(best.rgb, 0.95)
	if contrastRatio(fg, bg) < 4.5 {
		fg = blend(fg, RGB{R: 255, G: 255, B: 255}, 0.25)
	}
	return fg
}

func chooseAccents(cands []candidate, bg, fg RGB) []RGB {
	type scored struct {
		candidate
		score float64
	}

	tmp := make([]scored, 0, len(cands))
	for _, c := range cands {
		if c.s < 0.14 {
			continue
		}
		if c.l < 0.12 || c.l > 0.82 {
			continue
		}
		if contrastRatio(c.rgb, bg) < 1.65 {
			continue
		}
		if colorDistance(c.rgb, bg) < 28 || colorDistance(c.rgb, fg) < 34 {
			continue
		}
		score := math.Log(c.w+1)*1.4 + c.s*4.2 + (1.0-math.Abs(c.l-0.52))*1.2
		tmp = append(tmp, scored{candidate: c, score: score})
	}

	sort.Slice(tmp, func(i, j int) bool {
		return tmp[i].score > tmp[j].score
	})

	selected := make([]candidate, 0, 6)
	for _, c := range tmp {
		ok := true
		for _, s := range selected {
			if hueDistance(c.h, s.h) < 18 && math.Abs(c.l-s.l) < 0.2 {
				ok = false
				break
			}
		}
		if !ok {
			continue
		}
		selected = append(selected, c.candidate)
		if len(selected) == 6 {
			break
		}
	}

	for len(selected) < 6 {
		selected = append(selected, candidate{rgb: blend(bg, fg, float64(len(selected)+2)/8.0)})
	}

	accents := make([]RGB, 6)
	for i := 0; i < 6; i++ {
		accents[i] = selected[i].rgb
	}
	return accents
}

func buildPalette(bg, fg RGB, accents []RGB) [16]RGB {
	var out [16]RGB
	out[0] = bg
	out[1] = accents[1]
	out[2] = accents[2]
	out[3] = accents[0]
	out[4] = accents[3]
	out[5] = accents[4]
	out[6] = accents[5]
	out[7] = fg

	out[8] = blend(bg, fg, 0.28)
	for i := 0; i < 6; i++ {
		out[i+9] = blend(accents[i], fg, 0.22)
	}
	out[15] = blend(fg, RGB{R: 255, G: 255, B: 255}, 0.08)

	for i := 1; i <= 6; i++ {
		if contrastRatio(out[i], bg) < 1.5 {
			out[i] = blend(out[i], fg, 0.15)
		}
	}
	if contrastRatio(out[3], bg) < 1.8 {
		out[3] = blend(out[3], fg, 0.2)
	}
	return out
}

func hueDistance(a, b float64) float64 {
	d := math.Abs(a - b)
	if d > 180 {
		return 360 - d
	}
	return d
}

func colorDistance(a, b RGB) float64 {
	dr := float64(int(a.R) - int(b.R))
	dg := float64(int(a.G) - int(b.G))
	db := float64(int(a.B) - int(b.B))
	return math.Sqrt(dr*dr + dg*dg + db*db)
}

func rgbToHsl(r, g, b uint8) (float64, float64, float64) {
	rf, gf, bf := float64(r)/255.0, float64(g)/255.0, float64(b)/255.0
	max := math.Max(rf, math.Max(gf, bf))
	min := math.Min(rf, math.Min(gf, bf))
	l := (max + min) / 2
	if max == min {
		return 0, 0, l
	}

	d := max - min
	s := d / (1 - math.Abs(2*l-1))
	var h float64
	switch max {
	case rf:
		h = math.Mod(((gf - bf) / d), 6)
	case gf:
		h = ((bf-rf)/d + 2)
	default:
		h = ((rf-gf)/d + 4)
	}
	h *= 60
	if h < 0 {
		h += 360
	}
	return h, s, l
}

func relativeLuminance(c RGB) float64 {
	toLin := func(v uint8) float64 {
		s := float64(v) / 255.0
		if s <= 0.03928 {
			return s / 12.92
		}
		return math.Pow((s+0.055)/1.055, 2.4)
	}
	r := toLin(c.R)
	g := toLin(c.G)
	b := toLin(c.B)
	return 0.2126*r + 0.7152*g + 0.0722*b
}

func contrastRatio(a, b RGB) float64 {
	la := relativeLuminance(a)
	lb := relativeLuminance(b)
	if la < lb {
		la, lb = lb, la
	}
	return (la + 0.05) / (lb + 0.05)
}

func blend(a, b RGB, t float64) RGB {
	if t < 0 {
		t = 0
	}
	if t > 1 {
		t = 1
	}
	mix := func(x, y uint8) uint8 {
		v := float64(x)*(1-t) + float64(y)*t
		if v < 0 {
			v = 0
		}
		if v > 255 {
			v = 255
		}
		return uint8(v + 0.5)
	}
	return RGB{R: mix(a.R, b.R), G: mix(a.G, b.G), B: mix(a.B, b.B)}
}

func shade(c RGB, factor float64) RGB {
	apply := func(v uint8) uint8 {
		f := float64(v) * factor
		if f < 0 {
			f = 0
		}
		if f > 255 {
			f = 255
		}
		return uint8(f + 0.5)
	}
	return RGB{R: apply(c.R), G: apply(c.G), B: apply(c.B)}
}

func clampMinLuma(c RGB, target float64) RGB {
	if relativeLuminance(c) >= target {
		return c
	}
	return blend(c, RGB{R: 255, G: 255, B: 255}, 0.12)
}

func clampMaxLuma(c RGB, target float64) RGB {
	if relativeLuminance(c) <= target {
		return c
	}
	return blend(c, RGB{R: 0, G: 0, B: 0}, 0.12)
}

func rgbHex(c RGB) string {
	return fmt.Sprintf("#%02x%02x%02x", c.R, c.G, c.B)
}

func HexNoHash(h string) string {
	return strings.TrimPrefix(strings.ToLower(h), "#")
}

func maxInt(a, b int) int {
	if a > b {
		return a
	}
	return b
}
