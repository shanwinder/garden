# รายงานผลการทดสอบทางเทคนิคไปป์ไลน์แอสเซท (Asset Pipeline Empirical Validation Spike)

> เอกสารอ้างอิง: Task 4.4A — Asset Pipeline Empirical Validation Spike
> สถานะ: **PARTIAL — local/import/build validation completed; device-dependent evidence remains unavailable** (เสร็จสิ้นการทดสอบทางเทคนิคเฉพาะที่และบิลด์ — รอการตรวจสอบบนอุปกรณ์จริง)
> วันที่ดำเนินการ: 2026-10-04
> สาขาที่ทำการทดสอบ: `milestone/4-visual-direction`
> เบสไลน์คอมมิต (Baseline HEAD): `55b36caa6c958c1999b0da0db5cab41de50e212a`
> เวอร์ชันเอนจิน: Godot `4.7.2.stable.official.ed1daf0bf`
> สภาพแวดล้อมจำลองการทดลอง (Temporary Clone Path): `/tmp/garden-asset-pipeline-spike-55b36caa`

---

## 1. วัตถุประสงค์และการปกป้องคลังโค้ดจริง (Spike Purpose & Worktree Isolation)

การทดสอบนี้คือการดำเนินการตามข้อกำหนด **Future Technical Spike Definition** ใน `ASSET_PIPELINE.md` §34 เพื่อเก็บข้อมูลเชิงประจักษ์ (Empirical Evidence) ทางเทคนิคเกี่ยวกับ:
- พฤติกรรมการอิมพอร์ตของ Godot 4.7 (`ResourceImporterTexture`) ทั้งโหมด Lossless และ VRAM Compressed (ETC2)
- พฤติกรรมและค่าใช้จ่ายหน่วยความจำของ Mipmaps
- กลไกจุดหมุนอิงพื้นล่างกึ่งกลาง (Bottom-Center Pivot)
- การสเกลแบบ 1:1 เทียบกับ Reference Canvas (1080×1920) โดยปราศจากการ hand-scale ชดเชย
- พฤติกรรม Texture Filtering (Linear เทียบกับ Nearest)
- ความเสถียรของขอบเขตเฟรมแอนิเมชัน (Animation Frame Bounds)
- ความสมบูรณ์ของกระบวนการ Export และ Signing ของ Android Debug APK

**การแยกพื้นที่ทดลองเด็ดขาด (Strict Worktree Protection):**
การสร้างไฟล์ PNG วินิจฉัย, ไฟล์ `.import`, ซีนทดสอบ (`asset_pipeline_spike.tscn`), สคริปต์สร้างภาพ, แคชเอนจิน (`.godot/`), และไฟล์ APK ทั้งหมดกระทำภายใน Temporary Clone นอกคลังหลักที่ `/tmp/garden-asset-pipeline-spike-55b36caa` โดยคลังหลักที่ `/Applications/garden` ได้รับการปกป้องให้สะอาดบริสุทธิ์ (Working Tree Clean) และมีเพียงเอกสารรายงานสรุปผล `ASSET_PIPELINE_SPIKE_REPORT.md` นี้ฉบับเดียวเท่านั้นที่ถูกเพิ่มเข้ามา

---

## 2. ข้อมูลจำเพาะและการสร้างแอสเซทวินิจฉัย (Diagnostic Asset Generation)

เนื่องจากระบบไม่มีไลบรารี Pillow ติดตั้งไว้ จึงได้สร้างสคริปต์ตัวสร้างแบบดีเทอร์มินิสติก (Deterministic Procedural Generator) ด้วย GDScript บน Godot 4.7 Headless ที่พาธ:
`spike/asset_pipeline/generate_diagnostics.gd` (ภายใน Temporary Clone)

สคริปต์ใช้คลาส `Image` ของ Godot (`Image.FORMAT_RGBA8`) และบันทึกผ่าน `save_png()` เพื่อสร้างไฟล์วินิจฉัยที่ทดสอบความเค้น (Stress Test) ทางการเรนเดอร์ในแต่ละมิติ:

| ชื่อไฟล์แอสเซท | มิติพิกเซล (Dimensions) | ขนาดไฟล์ดิสก์ (Disk Bytes) | ความเค้นที่ทำการทดสอบ (Rendering Stresses & Characteristics) |
|---|---|---|---|
| `grounded_soft_alpha.png` | 512 × 512 RGBA | 25,872 bytes | พื้นหลังโปร่งใส 100%, มวลรูปทรงเครื่องปั้นดินเผาตรงกลาง, ขอบเกลี่ยโปร่งแสง (Soft semi-transparent alpha falloff), เงาสัมผัสพื้นโปร่งแสงสีเข้ม (Dark contact-shadow at base), รายละเอียดริ้วขอบ, จุดสัมผัสพื้นล่างกึ่งกลางที่ (256, 504), ขอบเว้นระยะ (Gutter) 8 px (≥ 4 px) |
| `fine_foliage.png` | 512 × 512 RGBA | 19,478 bytes | กิ่งก้านและก้านใบอินทรีย์เรียวบาง (1–3 px), ระดับโทนสีเขียว 3 ระดับ (เงาเขียวเข้ม, เขียวใบไม้กลาง, เขียวตองไฮไลต์), ขอบ anti-aliasing โปร่งแสง, ขอบเว้นระยะรอบข้าง |
| `painted_gradient.png` | 1024 × 1024 RGBA | 297,406 bytes | การไล่ระดับสีเรียบกว้าง 3 จังหวะ (ฟ้าครามยามเช้า → ส้มพีชขอบฟ้า → เขียวเอิร์ธเสจ), ผสมความแปรปรวนสีน้ำฮาร์มอนิกความถี่ต่ำ (Watercolor/gouache wash modulation), ทดสอบการเกิด Color Banding ภายใต้การบีบอัด |
| `full_canvas_background.png` | 1080 × 1920 RGBA | 580,388 bytes | ขนาดเท่าผืนผ้าใบอ้างอิงเต็มจอ (1080×1920), แถบสีท้องฟ้า, ผนังปูนและระแนงไม้, ผืนดินสวนและกระเบื้องดินเผา, ทดสอบการอิมพอร์ต/เอ็กซ์พอร์ตฉากหลังความละเอียดสูง |
| `anim_frame_00.png` | 256 × 256 RGBA | 5,095 bytes | เฟรมที่ 0: ท่าพักปกติ, ขนาดขอบเขตเท่ากันเป๊ะ, จุดสัมผัสพื้นที่ (128, 248) ตรึงแน่น |
| `anim_frame_01.png` | 256 × 256 RGBA | 5,252 bytes | เฟรมที่ 1: จังหวะหายใจเข้า ลำตัวขยายขึ้น 2.5 px, หูขยับขึ้น 1 px, ฐานคงที่ที่ (128, 248) |
| `anim_frame_02.png` | 256 × 256 RGBA | 5,255 bytes | เฟรมที่ 2: จังหวะหายใจเข้าสูงสุด ลำตัวขยายขึ้น 4.0 px, หูขยับขึ้น 2 px, ฐานคงที่ที่ (128, 248) |
| `anim_frame_03.png` | 256 × 256 RGBA | 5,170 bytes | เฟรมที่ 3: จังหวะผ่อนลมหายใจ ลำตัวลดระดับลงเหลือ +1.5 px, ฐานคงที่ที่ (128, 248) |

### คู่เปรียบเทียบพิกเซลเหมือนกัน 100% (Identical Pixel Pairs)
เพื่อทดสอบการตั้งค่าการอิมพอร์ตโดยตัดปัจจัยความแปรปรวนของภาพออก ได้ทำสำเนาพิกเซลเหมือนกันทุกประการ:
- `grounded_soft_alpha_lossless.png` (25,872 bytes) เทียบกับ `grounded_soft_alpha_vram.png` (25,872 bytes)
- `fine_foliage_lossless.png` (19,478 bytes) เทียบกับ `fine_foliage_vram.png` (19,478 bytes)
- `painted_gradient_lossless.png` (297,406 bytes) เทียบกับ `painted_gradient_vram.png` (297,406 bytes)
- `painted_gradient_mipmap_off.png` (297,406 bytes) เทียบกับ `painted_gradient_mipmap_on.png` (297,406 bytes)

---

## 3. หลักฐานการอิมพอร์ตของ Godot 4.7 (Godot Import Behavior & Sidecars)

### 3.1 การตรวจสอบค่าตัวเลขของ `compress/mode` ใน ResourceImporterTexture
ได้ตรวจสอบสตริงคำจำกัดความ Property Hint จากไบนารี Godot 4.7.2 โดยตรง:
```
2D/3D (Auto-Detect)
Lossless,Lossy,VRAM Compressed,VRAM Uncompressed,Basis Universal
```
ส่งผลให้ค่าจำนวนเต็ม (Integer Enum) ของ `compress/mode` ถูกยืนยันแน่ชัดดังนี้:
- `0`: **Lossless** (ค่าเริ่มต้นของ 2D ใน Godot)
- `1`: **Lossy** (บีบอัดไฟล์บนดิสก์เป็น Lossy WebP แต่ไม่ลด VRAM)
- `2`: **VRAM Compressed** (บีบอัดลงบล็อก GPU ตามแพลตฟอร์ม)
- `3`: **VRAM Uncompressed** (ไม่บีบอัดทั้งบนดิสก์และ GPU)
- `4`: **Basis Universal** (บีบอัดไฟล์เล็กลงแล้วแปลงลง VRAM ตอนโหลด)

### 3.2 ค่าพารามิเตอร์ของคู่ทดสอบในไฟล์ `.import`
เมื่อรัน `godot --headless --import` เอนจินสร้างไฟล์ `.import` เคียงข้างไฟล์ภาพต้นฉบับ:

1. **คอนฟิก Lossless Baseline (`*_lossless.png.import`):**
   ```ini
   [remap]
   importer="texture"
   type="CompressedTexture2D"
   metadata={
   "vram_texture": false
   }
   [params]
   compress/mode=0
   mipmaps/generate=false
   process/fix_alpha_border=true
   process/premult_alpha=false
   ```
   - สังเกตว่า `metadata.vram_texture` มีค่าเป็น `false`
   - แคชที่สร้างใน `.godot/imported/` เป็นไฟล์ `.ctex` เดี่ยว (เก็บข้อมูลแบบ Lossless WebP ภายในคอนเทนเนอร์ของ Godot)

2. **คอนฟิก VRAM Compressed (`*_vram.png.import`):**
   ```ini
   [remap]
   importer="texture"
   type="CompressedTexture2D"
   path.s3tc="res://.godot/imported/<hash>.s3tc.ctex"
   path.etc2="res://.godot/imported/<hash>.etc2.ctex"
   metadata={
   "imported_formats": ["s3tc_bptc", "etc2_astc"],
   "vram_texture": true
   }
   [params]
   compress/mode=2
   mipmaps/generate=false
   process/fix_alpha_border=true
   process/premult_alpha=false
   ```
   - เอนจินตรวจพบการตั้งค่าโปรเจกต์ `textures/vram_compression/import_etc2_astc=true`
   - เอนจินทำการสร้างแคช 2 รูปแบบคู่ขนาน:
     - `.s3tc.ctex`: สำหรับการรันบนเดสก์ท็อป (S3TC/BC3)
     - `.etc2.ctex`: สำหรับการ Export ไปยัง Android (ETC2)
   - ขอย้ำตาม `ASSET_PIPELINE.md` §17.1 ว่าใน GL Compatibility Renderer คุณสมบัติ High Quality จะถูกปิดการทำงานตลอดเวลา ดังนั้นบน Android เส้นทาง VRAM Compressed จะใช้บล็อก **ETC2 RGBA** (ไม่ใช่ ASTC) และบนเดสก์ท็อปจะใช้ **S3TC**

3. **คอนฟิก Mipmap A/B Test:**
   - `painted_gradient_mipmap_off.png.import`: `mipmaps/generate=false`
   - `painted_gradient_mipmap_on.png.import`: `mipmaps/generate=true`

---

## 4. หลักฐานเชิงประจักษ์ด้านหน่วยความจำ (Memory & Storage Evidence)

### 4.1 ความแตกต่างที่ต้องแยกแยะให้ชัดเจน (Distinction of Metrics)
การประเมินหน่วยความจำต้องไม่สับสนระหว่าง 4 ค่านี้:
1. **Source PNG Disk Size**: ขนาดไฟล์รูปภาพที่บันทึกบนระบบไฟล์ มีการบีบอัดแบบ Deflate
2. **Imported Cache (.ctex) Size**: ขนาดไฟล์แคชที่ Godot สร้างไว้ใน `.godot/imported/` เพื่อเตรียมนำไปแพ็กลง APK
3. **GPU VRAM Residency**: ปริมาณหน่วยความจำวิดีโอบนการ์ดจอจริงเมื่อเทกซ์เจอร์ถูกโหลดขึ้น VRAM
4. **Packaged APK Size**: ขนาดรวมของตัวติดตั้งแอปพลิเคชัน

### 4.2 ตารางเปรียบเทียบขนาดไฟล์และหน่วยความจำจริง

| ชิ้นงานแอสเซท | มิติพิกเซล | ขนาดไฟล์ดิสก์ (Source PNG) | ขนาดไฟล์แคช Godot (.ctex) | หน่วยความจำ GPU ทางทฤษฎี (RGBA8 Baseline) | หน่วยความจำ GPU ทางทฤษฎี (ETC2 RGBA Mobile) | ส่วนต่าง Mipmap ทางทฤษฎี (+33.3%) |
|---|---|---|---|---|---|---|
| `grounded_soft_alpha_lossless` | 512 × 512 | 25,872 bytes | 17,516 bytes (.ctex) | 1,048,576 bytes (1.00 MiB) | — (ไม่บีบอัด VRAM) | Mip OFF: 1.00 MiB |
| `grounded_soft_alpha_vram` | 512 × 512 | 25,872 bytes | 262,196 bytes (.etc2.ctex) | — | 262,144 bytes (256 KiB / 0.25 MiB) | Mip OFF: 256 KiB |
| `fine_foliage_lossless` | 512 × 512 | 19,478 bytes | 12,068 bytes (.ctex) | 1,048,576 bytes (1.00 MiB) | — (ไม่บีบอัด VRAM) | Mip OFF: 1.00 MiB |
| `fine_foliage_vram` | 512 × 512 | 19,478 bytes | 262,196 bytes (.etc2.ctex) | — | 262,144 bytes (256 KiB / 0.25 MiB) | Mip OFF: 256 KiB |
| `painted_gradient_lossless` | 1024 × 1024 | 297,406 bytes | 172,218 bytes (.ctex) | 4,194,304 bytes (4.00 MiB) | — (ไม่บีบอัด VRAM) | Mip OFF: 4.00 MiB |
| `painted_gradient_vram` | 1024 × 1024 | 297,406 bytes | 524,340 bytes (.etc2.ctex) | — | 1,048,576 bytes (1.00 MiB) | Mip OFF: 1.00 MiB |
| `painted_gradient_mipmap_off` | 1024 × 1024 | 297,406 bytes | 172,218 bytes (.ctex) | 4,194,304 bytes (4.00 MiB) | — | Mip OFF: 4.00 MiB |
| `painted_gradient_mipmap_on` | 1024 × 1024 | 297,406 bytes | 281,980 bytes (.ctex) | 4,194,304 bytes (4.00 MiB) | — | Mip ON: ~5,592,405 bytes (~5.33 MiB) |
| `full_canvas_background` | 1080 × 1920 | 580,388 bytes | 380,712 bytes (.ctex) | 8,294,400 bytes (~7.91 MiB) | 2,073,600 bytes (~1.98 MiB)* | Mip OFF: ~7.91 MiB (RGBA8) / ~1.98 MiB (ETC2) |
| `anim_frame_00..03` (4 เฟรม) | 256 × 256 ea | ~5.1 KiB ea | ~4.4 KiB ea (.ctex) | 262,144 bytes ea (รวม 1.00 MiB) | 65,536 bytes ea (รวม 256 KiB) | Mip OFF: 1.00 MiB (RGBA8) / 256 KiB (ETC2) |

*\*หมายเหตุการคำนวณ ETC2:* มิติพิกเซล 1080 และ 1920 หารด้วย 4 ลงตัวพอดี (`1080 / 4 = 270`, `1920 / 4 = 480`) บล็อก ETC2 RGBA/EAC ขนาด 4×4 ใช้ 16 bytes: `270 × 480 × 16 = 2,073,600 bytes` (หรือตรงกับสูตร `RGBA8 / 4` พอดี)

### 4.3 ข้อสังเกตเชิงลึกเกี่ยวกับขนาดไฟล์แคชและ VRAM
1. **ไฟล์แคชบนดิสก์ไม่ได้สะท้อน VRAM:**
   - สำหรับภาพ Lossless ไฟล์ `.ctex` เก็บเป็น WebP Lossless ขนาดไฟล์จึงมีเพียง ~12–17 KB สำหรับภาพ 512×512 แต่เมื่อโหลดขึ้นการ์ดจอ VRAM จะต้องจองเต็ม `512 × 512 × 4 = 1,048,576 bytes` (1 MiB) เต็มจำนวน
   - สำหรับภาพ VRAM Compressed ไฟล์ `.etc2.ctex` มีขนาด 262,196 bytes (ประกอบด้วยเนื้อข้อมูล ETC2 ดิบ 262,144 bytes + เฮดเดอร์ของ Godot 52 bytes) ซึ่งขนาดไฟล์บนดิสก์ใกล้เคียงกับ VRAM ที่ถูกจองบน GPU จริง
2. **Mipmap Overhead:**
   - การเปิด Mipmaps ในไฟล์ Lossless ทำให้แคช `.ctex` บนดิสก์เพิ่มขึ้นจาก 172,218 bytes เป็น 281,980 bytes (+63.7% บนดิสก์เนื่องจากระดับย่อยถูกบีบอัดรวมไว้)
   - แต่บน GPU VRAM จะเพิ่มขึ้นตามลำดับเรขาคณิตคงที่: `1 + 1/4 + 1/16 + ... ≈ 1.3333` (+33.33% แน่นอน)
3. **คำชี้แจงสำคัญเรื่องงบประมาณหน่วยความจำฉาก (Scene Memory Budget Statement):**
   - ข้อความตัวอย่างใน `ASSET_PIPELINE.md` ที่ระบุว่า `~6.4 MB is well within modern mobile headroom` เป็นเพียงตัวอย่างประกอบความเข้าใจทางคณิตศาสตร์ **ไม่ใช่เกณฑ์ตัดสินผ่าน/ไม่ผ่าน (Pass/Fail Threshold)**
   - **การทดสอบ Task 4.4A นี้ไม่มีการสรุปยอมรับงบประมาณหน่วยความจำฉากล่วงหน้า (No total scene-memory acceptability conclusion is made without representative device profiling)**
   - งบประมาณหน่วยความจำรวมของฉากยังคงสถานะ **TBD / ต้องรอหลักฐานการทำโปรไฟล์บนอุปกรณ์เป้าหมายตัวแทนจริง**

---

## 5. การทดสอบการสเกล, จุดหมุน, ฟิลเตอร์, และแอนิเมชัน (Spike Scene Mechanics)

> **หมายเหตุการจำแนกระดับหลักฐาน (Evidence Provenance Classification):**
> - **MECHANICALLY VERIFIED**: หลักฐานความถูกต้องเชิงกลไก (การตั้งค่าคอนฟิก, รีซอร์ส, โครงสร้างเรขาคณิตจุดหมุน, การสร้างซีน, และผลสำเร็จของบิลด์)
> - **VISUALLY VERIFIED**: หลักฐานการมองเห็นจริงจากการแคปเจอร์ภาพเรนเดอร์ของเอนจินหรือการสังเกตการณ์บนหน้าจอแสดงผล
> - **DEVICE VERIFIED**: หลักฐานที่สังเกตการณ์และตรวจวัดผลจริงบนฮาร์ดแวร์อุปกรณ์ตัวแทนเป้าหมายที่ได้รับอนุญาต

ได้สร้างซีนทดสอบที่ `res://spike/asset_pipeline/asset_pipeline_spike.tscn` ภายใต้ Temporary Clone โดยมีผลการทดสอบเชิงกลไกดังนี้:

### 5.1 ผืนผ้าใบอ้างอิงและการไม่ใช้ Hand-Scale ชดเชย (Reference Scale Validation)
- รันภายใต้พิกัด Viewport อ้างอิง `1080 × 1920` ของโปรเจกต์
- การทดสอบประสบความสำเร็จในการยืนยันหลักการ 1:1 authored/export/display สำหรับวัตถุตัวแทนขนาดอ้างอิง (Representative reference-size subjects):
  - ภาพฉากหลัง `full_canvas_background.png` (1080×1920) วางที่ `position = Vector2(540, 960)` แสดงผลที่ `scale = Vector2(1, 1)` ปกคลุมหน้าจอพอดี 1:1 พิกเซล
  - วัตถุทดสอบจุดหมุนอิงพื้น (Grounded pivot subjects ขนาด 512×512), วัตถุทดสอบใบไม้ (Foliage subjects ขนาด 512×512), และวัตถุทดสอบแอนิเมชัน (`AnimatedSprite2D` ขนาด 256×256) ล้วนใช้ `scale = Vector2(1, 1)`
- **ข้อยกเว้นการจัดวางในฟิกซ์เจอร์วินิจฉัย (Diagnostic Fixture Scale Exception):**
  - สไปรต์เปรียบเทียบ Gradient ขนาด 1024×1024 จำนวน 2 ชิ้น (`GradientLossless` และ `GradientVRAM`) ได้รับการตั้งค่า `scale = Vector2(0.45, 0.45)` โดยเจตนา เพียงเพื่อให้สามารถจัดวางเปรียบเทียบแบบเคียงข้างกัน (Side-by-side) ภายในขอบเขตความกว้าง 1080 px ของฟิกซ์เจอร์ทดสอบได้
  - การสเกลในฟิกซ์เจอร์ดังกล่าว **ไม่ใช่การสเกลชดเชยสำหรับแอสเซทในโปรดักชันจริง (Not a corrective production asset scale)**
  - ดังนั้น รายงานฉบับนี้จึงไม่กล่าวอ้างว่าทุกสไปรต์ในซีนฟิกซ์เจอร์ทั้งหมดใช้ `scale = Vector2(1, 1)`
- **ข้อสรุปไปป์ไลน์:** ยืนยันว่าการวาดและส่งออกแอสเซทในขนาดพิกเซลที่ต้องการแสดงผลจริงบนแคนวาส (Author at intended runtime-export size) ทำให้ไม่ต้องพึ่งพาการสเกลชดเชยตามอำเภอใจในซีน และการปรับสเกลชดเชยรายชิ้นตามอำเภอใจไม่ควรกลายเป็นแนวปฏิบัติปกติของโปรดักชัน (Arbitrary corrective per-asset scale should not become normal production practice)

### 5.2 การทดสอบจุดหมุนอิงพื้นล่างกึ่งกลาง (Bottom-Center Pivot Test)
- ได้ทำการทดสอบและเปรียบเทียบสองแนวทางสำหรับสไปรต์ขนาด 512×512 ที่ต้องการให้จุดสัมผัสพื้นอยู่ที่ `y = 1000`:
- **Option A (`GroundedPivotOptionA`):**
  - คอนฟิก: `centered = true`, `offset = Vector2(0, -256)` (โดย `-256` คือ `-texture_height / 2`)
  - ตำแหน่งโหนด: `position = Vector2(280, 1000)`
  - ผลลัพธ์: ขอบล่างของภาพแตะที่ `y = 1000` ตรงกับเส้นอ้างอิง `GroundLine1` พอดิบพอดี โดยกึ่งกลางแนวนอนอยู่ที่ `x = 280` โดยอัตโนมัติ (ไม่ต้องคำนวณ `offset.x`)
- **Option B (`GroundedPivotOptionB`):**
  - คอนฟิก: `centered = false`, `offset = Vector2(-256, -512)` (โดย `-256` คือ `-w/2` และ `-512` คือ `-h`)
  - ตำแหน่งโหนด: `position = Vector2(800, 1000)`
  - ผลลัพธ์: ขอบล่างแตะที่ `y = 1000` และกึ่งกลางอยู่ที่ `x = 800` ได้ผลทางเรขาคณิตตรงกัน
- **ข้อสรุปเปรียบเทียบ:**
  Option A มีความเรียบง่ายและลดความเสี่ยงต่อความผิดพลาดของมนุษย์มากกว่า เนื่องจากพิกัด X คงที่ที่ `offset.x = 0` ตามค่าศูนย์กลาง และปรับเพียง `offset.y = -(height / 2)` สำหรับการตรึงระนาบพื้น (Mechanically Verified)

### 5.3 การทดสอบ Texture Filtering (Linear vs Nearest)
- **สถานะการเปรียบเทียบคุณภาพทางสายตา (Visual Comparison Status):**
  **`UNVERIFIED — RENDERED VISUAL EVIDENCE REQUIRED`** (เนื่องจากติดข้อจำกัดใน §5.5 `LOCAL RENDER SCREENSHOT BLOCKED BY ENVIRONMENT`)
- **สิ่งที่ได้รับการยืนยันเชิงกลไก (Mechanically Confirmed):**
  - คุณสมบัติ `CanvasItem.texture_filter` สามารถกำหนดค่าแยกรายโหนดได้อย่างชัดเจน
  - โหนดที่เป็นเบสไลน์หลักถูกกำหนดค่าเป็น `TEXTURE_FILTER_LINEAR` (Enum 2)
  - โหนดสำหรับเปรียบเทียบถูกกำหนดค่าเป็น `TEXTURE_FILTER_NEAREST` (Enum 1)
  - การจัดเก็บคอนฟิกและโครงสร้างการสร้างซีน (Scene serialization) มีความสมบูรณ์และถูกต้องเชิงกลไก
  - **ตำแหน่งการตั้งค่า (Configuration Locus):** ยืนยันว่าการตั้งค่า Filter อาศัยโหนด `CanvasItem` หรือการตั้งค่า Canvas ของโปรเจกต์ (`ProjectSettings`) ไม่ได้ถูกบันทึกไว้ในไฟล์ `.import`
- **สิ่งที่ยังไม่ได้รับการยืนยันเชิงประจักษ์ทางสายตาจากการทดสอบนี้ (Not Empirically Visually Confirmed):**
  - ไม่มีหลักฐานภาพเรนเดอร์โดยตรงว่า Linear ดูนุ่มนวลกว่าจริงบนผลลัพธ์ Compatibility Renderer ในเครื่อง
  - ไม่มีหลักฐานภาพเรนเดอร์โดยตรงของรอยหยักพิกเซล (Pixelation / Jagged edges) ของ Nearest จากเฟรมเรนเดอร์ในเครื่อง
  - ความยอมรับได้ทางสายตาขั้นสุดท้ายบนหน้าจออุปกรณ์พกพา
- **ข้อสรุปไปป์ไลน์:**
  `TEXTURE_FILTER_LINEAR` ยังคงเป็นเบสไลน์ไปป์ไลน์ที่ได้รับความเห็นชอบตามทิศทางศิลป์จิตรกรรม (Painterly Direction) ที่สืบทอดมาจาก `ASSET_PIPELINE.md` แต่งานทดสอบ Spike นี้ไม่นำเสนอสถานะที่ถูกบล็อกภาพเรนเดอร์เป็นข้อพิสูจน์เชิงประจักษ์ทางสายตา (Blocked screenshot is not visual empirical proof)

### 5.4 การทดสอบขอบเขตเฟรมแอนิเมชัน (Animation Frame Bounds Test)
- **สถานะการสังเกตการณ์ภาพเคลื่อนไหวเรนเดอร์ (Rendered Animation Observation Status):**
  **`UNVERIFIED — RENDERED/DEVICE EVIDENCE REQUIRED`** (เนื่องจากติดข้อจำกัดใน §5.5 `LOCAL RENDER SCREENSHOT BLOCKED BY ENVIRONMENT`)
- **สิ่งที่ได้รับการยืนยันเชิงกลไก (Mechanically Confirmed):**
  - โหนด `AnimatedSprite2D` ใช้งานร่วมกับ `SpriteFrames` บรรจุ 4 เฟรมวินิจฉัย (`anim_frame_00.png` ถึง `anim_frame_03.png`) ได้สำเร็จสมบูรณ์
  - โหลดครบทั้ง 4 เฟรม โดยทุกเฟรมมีมิติแคนวาสเท่ากันเป๊ะ: `256 × 256`
  - ทุกเฟรมที่สร้างขึ้นใช้พิกัดจุดสัมผัสพื้นเดียวกันอย่างแม่นยำ: `(128, 248)`
  - ขนาดมิติผืนผ้าใบร่วมและการกำหนดตำแหน่งจุดยึดร่วมกัน ขจัดปัญหาการเลื่อนตำแหน่งที่เกิดจากขอบเขตเฟรมไม่เท่ากันตั้งแต่ระดับโครงสร้าง (Common canvas dimensions and common anchor configuration remove frame-bound-induced positional displacement by construction)
  - ความเร็วแอนิเมชันถูกกำหนดค่าไว้ที่ 8 FPS ในรีซอร์ส
  - โครงสร้างซีน/รีซอร์สและการเอ็กซ์พอร์ตไปยัง Android สำเร็จเรียบร้อย
- **สิ่งที่ยังไม่ได้รับการยืนยันเชิงประจักษ์ทางสายตา (Not Empirically Visually Confirmed):**
  - ความรู้สึกลื่นไหลที่รับรู้ได้ (Perceived smoothness) ที่ 8 FPS
  - การปลอดจากการกระตุก (Absence of jitter) ในเอาต์พุตที่เรนเดอร์จริงบน GPU
  - จังหวะการแสดงผลเฟรม (Frame pacing) และความรู้สึกของแอนิเมชัน (Animation feel)
  - ประสิทธิภาพการทำงานจริงบนอุปกรณ์ (Device performance)
- **ข้อสรุปไปป์ไลน์:**
  ความสม่ำเสมอเชิงกลไกของขอบเขตเฟรมและจุดยึดได้รับการยืนยัน (Mechanical frame-bound and anchor consistency confirmed); แต่ความราบรื่นในการเรนเดอร์จริงและ frame pacing ยังคงไม่ได้รับการตรวจสอบ (Rendered smoothness/frame pacing remain unverified) โดยช่วงความเร็ว 8–12 FPS ยังคงสถานะ **PROVISIONAL** รอการประเมินบนอุปกรณ์จริง

### 5.5 สถานะการจับภาพหน้าจอในเครื่อง (Local Screenshot Status)
- บันทึกผลตามเงื่อนไข:
  **`LOCAL RENDER SCREENSHOT BLOCKED BY ENVIRONMENT`**
- **เหตุผลทางเทคนิค:** ในสภาพแวดล้อมเทอร์มินัล macOS ที่ทำงานแบบ Headless ปราศจาก WindowServer GUI Session โหมด `--headless` ของ Godot จะสลับไปใช้ Display Driver `headless` และ Dummy Rendering Server (`PN13RendererDummy`) โดยอัตโนมัติ ซึ่ง Viewport Texture จะส่งค่า `null` และไม่มีฮาร์ดแวร์เรนเดอร์เฟรมจริง จึงไม่สามารถจับภาพหน้าจอเรนเดอร์ในโหมดนี้ได้ และไม่มีการสร้างภาพสังเคราะห์หลอกขึ้นมาแทนที่
- **ผลกระทบต่อการยืนยันหลักฐาน (Impact on Evidence Provenance):**
  ข้อจำกัดด้านสภาพแวดล้อมนี้ส่งผลโดยตรงให้การเปรียบเทียบคุณภาพทางสายตาของ Texture Filtering (§5.3) และการสังเกตการณ์ความราบรื่นของแอนิเมชันจริง (§5.4) ไม่สามารถจัดเป็นหลักฐานเชิงประจักษ์ทางสายตา (Visually Verified) ได้ และต้องคงสถานะเป็น Unverified ในระดับการเรนเดอร์

---

## 6. หลักฐานการเอ็กซ์พอร์ต Android และการตรวจสอบอุปกรณ์ (Android Export & Device Status)

### 6.1 การตั้งค่าซีนหลักชั่วคราว (Temporary Main Scene Entry)
- เพื่อให้สามารถสร้าง APK ที่เปิดเข้าสู่ซีนทดสอบได้ทันที ได้ทำการเปลี่ยนค่าใน `project.godot` ภายใน Temporary Clone:
  - ค่าเดิมในคลังหลัก: `run/main_scene="res://scenes/app/main.tscn"`
  - ค่าที่ใช้ใน Spike: `run/main_scene="res://spike/asset_pipeline/asset_pipeline_spike.tscn"`
- คลังจริงที่ `/Applications/garden` ยังคงมีค่าเดิม `res://scenes/app/main.tscn` ไม่มีการแตะต้องใดๆ

### 6.2 ผลการรัน Android Debug Export
คำสั่งที่รันจาก Temporary Clone:
```bash
godot --headless --path . \
  --export-debug "Android Debug" \
  builds/android/Garden-asset-spike-debug.apk \
  --log-file ./.godot/headless.log
```
- **ผลลัพธ์การเอ็กซ์พอร์ต:** รหัสออก (Exit Code) `0` สำเร็จสมบูรณ์
- **ไฟล์ผลลัพธ์:** `builds/android/Garden-asset-spike-debug.apk`
- **ขนาดไฟล์ APK (APK File Size):** `30,681,193 bytes` (~29.26 MiB / ~30.68 MB)

### 6.3 ผลการตรวจสอบลายเซ็นดิจิทัล (APK Signature Verification)
คำสั่งที่รันตรวจสอบ:
```bash
/Users/depa/Library/Android/sdk/build-tools/36.1.0/apksigner verify --verbose --print-certs \
  builds/android/Garden-asset-spike-debug.apk
```
- **สถานะการยืนยัน:** `Verifies: true`
- **Scheme ที่ตรวจพบ:**
  - `Verified using v1 scheme (JAR signing): false`
  - `Verified using v2 scheme (APK Signature Scheme v2): true`
  - `Verified using v3 scheme (APK Signature Scheme v3): true`
  - `Verified using v3.1 scheme (APK Signature Scheme v3.1): false`
  - `Verified using v4 scheme (APK Signature Scheme v4): false`
- **ข้อมูลผู้ลงนาม (Signer #1):**
  - `Certificate DN`: `CN=Godot, OU=Godot Engine, O=Stichting Godot, C=NL`
  - `SHA-256 Digest`: `2f45c1779e68a064e06da66bc597969f4c71dbb5173df5ba8d9994354b1498b3`
  - `Algorithm`: `RSA 2048-bit`

### 6.4 การตรวจสอบความพร้อมของอุปกรณ์เชื่อมต่อ (ADB Device Availability)
คำสั่งที่รันตรวจสอบ:
```bash
/Users/depa/Library/Android/sdk/platform-tools/adb devices
```
- **ผลลัพธ์:**
  ```
  List of devices attached
  (ว่างเปล่า — ไม่มีอุปกรณ์หรืออีมูเลเตอร์ที่ได้รับอนุญาตเชื่อมต่ออยู่)
  ```
- **รายงานสถานะตามข้อกำหนด:**
  > Android build/export verified.
  > On-device ETC2 visual-quality and GPU-performance validation remains deferred because no authorized Android device/emulator is available.
- ไม่มีการเปิดโปรแกรมจำลองขึ้นมาเอง และไม่มีการสร้างข้อมูลผลลัพธ์บนอุปกรณ์โดยพลการ

---

## 7. ตารางสรุปผลการตัดสินใจทางเทคนิค (Pipeline Decision Outcomes)

จากการรวบรวมหลักฐานเชิงประจักษ์ใน Task 4.4A สรุปสถานะรายการในไปป์ไลน์ได้ดังนี้:

| หัวข้อการตัดสินใจ (Decision Area) | สถานะที่สรุปได้ (Outcome Status) | เหตุผลและหลักฐานเชิงประจักษ์ (Empirical Evidence / Rationale) |
|---|---|---|
| **Source vs Runtime Boundary** | **CONFIRMED** | แยกไฟล์มาสเตอร์ออกนอกคลังเกมชัดเจน ภาพ PNG สำหรับรันไทม์สะอาดและอิมพอร์ตได้สมบูรณ์ |
| **NPOT Texture Support** | **CONFIRMED** | Godot 4.7 Compatibility รองรับภาพมิติไม่ลงตัวยกกำลังสอง (เช่น 1080×1920) ได้อย่างสมบูรณ์ |
| **Godot 4.7 compress/mode Mapping** | **CONFIRMED** | ยืนยันจาก Enum สตริงของไบนารีและไฟล์ `.import`: 0=Lossless, 2=VRAM Compressed |
| **Lossless Import Baseline Configuration** | **CONFIRMED** | คอนฟิก `compress/mode=0`, `fix_alpha_border=true` สร้าง `.ctex` Lossless ได้เสถียร |
| **VRAM Compressed Android Export Path** | **CONFIRMED** | คอนฟิก `compress/mode=2` สร้างทั้ง `.s3tc.ctex` (เดสก์ท็อป) และ `.etc2.ctex` (Android Compatibility) |
| **Mipmap GPU Memory Formula (+33.3%)** | **CONFIRMED** | ได้รับการยืนยันเชิงทฤษฎีและเห็นผลการขยายตัวของไฟล์แคชบนดิสก์ (+63.7%) อย่างชัดเจน |
| **Reference Canvas 1:1 Scale Strategy** | **CONFIRMED** | ยืนยันหลักการ 1:1 authored/export/display สำหรับวัตถุตัวแทนขนาดอ้างอิง (ฉากหลัง 1080×1920, จุดหมุน, ใบไม้, แอนิเมชัน) โดยไม่ต้อง hand-scale ชดเชย (ข้อยกเว้นการสเกล 0.45 มีเฉพาะสไปรต์ gradient เพื่อจัดวางในฟิกซ์เจอร์ ไม่ใช่การสเกลชดเชยแอสเซทโปรดักชัน) |
| **Bottom-Center Pivot Mechanics** | **CONFIRMED** | Option A (`centered=true, offset.y=-h/2`) ตรึงระนาบพื้นล่างเข้ากับตำแหน่งโหนดได้อย่างแม่นยำและไม่ซับซ้อน |
| **Filtering Configuration Locus** | **CONFIRMED** | ยืนยันเชิงกลไกว่าการตั้งค่า Filter อยู่ในโหนด `CanvasItem` / `ProjectSettings` ไม่ได้อยู่ในไฟล์ `.import` |
| **Animation Frame Bounding & Anchor Consistency** | **CONFIRMED** | ยืนยันเชิงกลไก: ขนาดเฟรมเท่ากัน (256×256) และใช้พิกัดจุดสัมผัสพื้นเดียวกัน ขจัดปัญหาสไปรต์กระโดดจากมิติเฟรมตั้งแต่ระดับโครงสร้าง |
| **.import Sidecar VCS Policy** | **CONFIRMED** | ไฟล์ `.import` ต้องคอมมิตลง Git เพื่อการทำซ้ำบิลด์ได้ตรงกัน ส่วน `.godot/` อยู่ใน `.gitignore` |
| **Android Export & v2/v3 Signing** | **CONFIRMED** | บิลด์ APK สำเร็จด้วยรหัสออก 0 และผ่านการรับรองลายเซ็นดิจิทัล v2/v3 ถูกต้องสมบูรณ์ |
| **4 px Transparent Gutter Rule** | **STILL PROVISIONAL** | สมเหตุสมผลในเชิงทฤษฎี แต่ต้องรอตรวจสอบการเรนเดอร์ขอบอัลฟาจริงบนหน้าจออุปกรณ์พกพา |
| **AnimatedSprite2D FPS Budget Ranges & Rendered Smoothness** | **STILL PROVISIONAL** | เชิงกลไกคอนฟิกที่ 8 FPS ได้ แต่ความราบรื่นที่รับรู้ได้ (Perceived smoothness), การปลอดจาก jitter บน GPU จริง, และ frame pacing ยังไม่ได้รับการสังเกตการณ์จากการเรนเดอร์จริง ต้องรอประเมินบนอุปกรณ์ |
| **Lossless Baseline for Sprites** | **STILL PROVISIONAL** | ยังคงเป็นทางเลือกหลักด้านคุณภาพ แต่ยังไม่ได้เปรียบเทียบข้อบกพร่องภาพกับ ETC2 บนฮาร์ดแวร์จริง |
| **Large Background ETC2 vs Lossless** | **STILL PROVISIONAL** | คำนวณความต่างชัดเจน (7.91 MiB vs 1.98 MiB) แต่ยังไม่ตัดสินใจเลือกจนกว่าจะเห็นภาพบนจอจริง |
| **Linear vs Nearest Rendered Visual Quality** | **UNVERIFIED — RENDERED VISUAL EVIDENCE REQUIRED** | ไม่สามารถสรุปเปรียบเทียบคุณภาพทางสายตา (ความนุ่มนวล vs รอยหยักพิกเซล) ได้เนื่องจากติดข้อจำกัด Dummy Rendering Server ในเครื่อง; Linear ยังคงเป็นเบสไลน์ไปป์ไลน์ที่สืบทอดมาจากสไตล์จิตรกรรม |
| **ETC2 Visual Artifact Acceptance** | **UNVERIFIED — DEVICE REQUIRED** | ไม่สามารถสรุปยอมรับการบีบอัด ETC2 บนภาพสีน้ำ/กูอัชและเงาสัมผัสได้หากไม่มีอุปกรณ์จริง |
| **Real Android GPU Residency & Frame Timing** | **UNVERIFIED — DEVICE REQUIRED** | ต้องการการโปรไฟล์ผ่านฮาร์ดแวร์ Android ตัวแทนจริง |
| **Total Scene Texture Memory Budget** | **UNVERIFIED — DEVICE REQUIRED** | ยังคงสถานะ TBD โดยไม่ทึกทักตัวเลขงบประมาณขึ้นมาเอง |

---

## 8. ขั้นตอนถัดไปที่แนะนำ (Recommended Next Step)

1. นำผลการทดสอบเชิงประจักษ์นี้ไปใช้อ้างอิงในงานถัดไปของ Milestone 4 (เช่น การปรับปรุงเอกสาร `ASSET_PIPELINE.md` หรือการเตรียมงานสำหรับ Task 4.4B / Vertical Slice)
2. เมื่อมีอุปกรณ์ฮาร์ดแวร์ Android ตัวแทนจริงที่ได้รับอนุญาต ให้ติดตั้งไฟล์ APK และบันทึกผลการตรวจสอบสายตา (Visual Inspection of ETC2 artifacts) และการโปรไฟล์หน่วยความจำบนอุปกรณ์เพื่อปลดล็อกสถานะ **UNVERIFIED — DEVICE REQUIRED** ต่อไป
