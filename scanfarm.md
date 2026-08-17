# SMARTFARMING – Farmer Side Soil Monitoring Screen Scanner

Act as a senior Flutter developer, computer vision/OCR engineer, and UI/UX designer.

Implement a new **Soil Sensor Screen Scanner** feature on the **Farmer Side** of the existing SMARTFARMING application.

## 1. MAIN OBJECTIVE

The farmer uses a handheld **Intelligent Soil Detector** device similar to the reference image provided.

The device displays soil and environmental measurements on its LCD screen.

The SMARTFARMING mobile application must allow the farmer to:

1. Open the Soil Monitoring feature.
2. Tap **"Scan Sensor"**.
3. Open the phone camera.
4. Point the camera at the sensor's LCD screen.
5. Capture the screen.
6. Automatically detect and crop the sensor display.
7. Extract the displayed measurements using OCR/computer vision.
8. Display the extracted values in editable fields.
9. Clearly tell the farmer to verify the extracted values.
10. Allow the farmer to correct any incorrectly detected values.
11. Only save the sensor reading after the farmer explicitly confirms it.
12. Store the verified sensor data using the application's existing soil monitoring/database architecture.

IMPORTANT:

**Never automatically save OCR results immediately after scanning.**

The farmer MUST have an opportunity to review and confirm the extracted values first.

---

# 2. SENSOR DATA TO EXTRACT

Based on the provided Intelligent Soil Detector reference image, detect the following values from the screen:

### Soil

* Fertility
* Moisture
* pH
* Temperature

### Environment

* Sunlight
* Humidity

The scanner should also detect the units displayed by the device whenever possible.

Expected examples:

* Fertility: `8 µS/cm`
* Moisture: `8 %`
* pH: `7.7`
* Temperature: `88 °F`
* Sunlight: `888 LUX`
* Humidity: `36 %`

These values are examples only.

**Do not hardcode these example values.**

The application must extract the actual values shown on the scanned device.

---

# 3. CAMERA SCANNING EXPERIENCE

Create a dedicated scanning interface.

Example UI:

**Scan Soil Sensor**

"Place the sensor display inside the scanning frame."

Show:

* Live camera preview
* Scanning frame/guide
* Sensor-screen positioning guide
* Flash/torch button
* Capture button
* Cancel button

The scanning frame should visually guide the farmer to capture only the LCD display.

Display helpful instructions such as:

> Keep the sensor screen inside the frame.

> Make sure the display is clearly visible.

> Avoid glare and strong reflections.

> Hold the phone steady.

---

# 4. IMAGE PROCESSING

Because the device uses a digital LCD/7-segment-style display, do NOT rely only on basic OCR.

Implement a robust processing pipeline.

After the image is captured:

1. Detect the sensor display area.
2. Crop the LCD region.
3. Correct perspective if the phone is tilted.
4. Resize the cropped display.
5. Improve contrast.
6. Reduce noise.
7. Handle different lighting conditions.
8. Detect the LCD characters.
9. Recognize numbers and decimal points.
10. Recognize measurement units where possible.
11. Map each detected number to the correct measurement field.

The processing should work even when:

* The photo is slightly tilted.
* The farmer is holding the phone at an angle.
* Lighting is not perfect.
* The LCD has mild reflections.
* The image contains the entire physical device rather than only the screen.

---

# 5. 7-SEGMENT DISPLAY RECOGNITION

The sensor uses digital-looking LCD characters.

Implement recognition that is optimized for:

* Seven-segment digits
* LCD digits
* Decimal points
* Percentage symbols
* Temperature values
* Numeric readings

Use appropriate image preprocessing such as:

* Grayscale conversion
* Adaptive thresholding
* Contrast enhancement
* Sharpening
* Noise reduction
* Perspective correction
* Digit segmentation

If the existing project already has an OCR/ML package, reuse it where appropriate.

If necessary, use a suitable mobile OCR/computer-vision solution compatible with the existing Flutter architecture.

Do not introduce a large or unnecessary dependency if an existing project dependency can perform the task.

---

# 6. FIELD MAPPING

The scanner must understand which value belongs to which sensor measurement.

Map the detected values according to the sensor's screen layout:

```text
Soil
 ├── Fertility
 ├── Moisture
 ├── pH
 └── Temperature

Environment
 ├── Sunlight
 └── Humidity
```

Do NOT simply extract all numbers and place them randomly into fields.

The system must use the visual position/label of each reading to determine the correct field.

For example:

```text
Fertility → numeric value beside "Fertility"
Moisture → numeric value beside "Moisture"
pH → numeric value beside "PH"
Temperature → numeric value beside "Temp"
Sunlight → numeric value beside "Sun light"
Humidity → numeric value beside "Humidity"
```

---

# 7. OCR RESULT REVIEW SCREEN

After scanning, DO NOT save the results.

Instead, navigate to a confirmation screen.

Title:

**Review Sensor Data**

Subtitle:

**Please check the detected values before saving.**

Display the extracted values in clean cards or form fields.

Example:

```text
SOIL SENSOR DATA

Fertility
[ 8 ] µS/cm

Moisture
[ 8 ] %

pH
[ 7.7 ]

Temperature
[ 88 ] °F

ENVIRONMENT

Sunlight
[ 888 ] LUX

Humidity
[ 36 ] %
```

Every value must be editable.

The farmer should be able to manually correct an OCR mistake.

---

# 8. OCR CONFIDENCE

If possible, calculate a confidence score for each detected value.

Example:

```text
Fertility       85%
Moisture        96%
pH              91%
Temperature     98%
Sunlight        72%
Humidity        94%
```

If a value has low confidence, visually warn the farmer.

Example:

**⚠ Low confidence**

"Please verify this reading."

Do not prevent the farmer from manually entering/correcting a value.

---

# 9. VALIDATION

Before saving, validate the extracted values.

Use reasonable sensor-value validation.

Examples:

### Fertility

Must be a valid numeric value.

### Moisture

Must be a valid percentage.

Recommended range:

```text
0–100%
```

### pH

Recommended range:

```text
0–14
```

### Humidity

Recommended range:

```text
0–100%
```

### Temperature

Allow valid temperature values according to the unit displayed by the device.

### Sunlight

Must be a valid non-negative numeric value.

Do not reject legitimate sensor readings simply because they are unusual.

If a value appears suspicious, show a warning rather than silently changing it.

---

# 10. UNIT HANDLING

The application must preserve the unit displayed by the device.

Temperature may be:

```text
°C
°F
```

The application should detect which unit is displayed.

If the device displays °F:

```text
Temperature: 88 °F
```

If the device displays °C:

```text
Temperature: 31 °C
```

Do not automatically convert or overwrite the original sensor reading unless the existing system specifically requires conversion.

---

# 11. MANUAL CORRECTION

Every extracted field must be editable.

For example:

```text
Fertility
[ 8            ]

Moisture
[ 82           ]

pH
[ 6.5          ]

Temperature
[ 31           ]

Sunlight
[ 450          ]

Humidity
[ 74           ]
```

The farmer can correct OCR errors before saving.

Examples of possible OCR errors:

```text
88 → 83
6.5 → 65
36 → 38
800 → 600
```

The farmer must be able to fix these manually.

---

# 12. CONFIRMATION BEFORE DATABASE SAVE

The save process must have an explicit confirmation step.

Primary button:

**Confirm & Save Sensor Data**

Secondary button:

**Scan Again**

When the farmer taps **Confirm & Save Sensor Data**:

1. Validate all fields.
2. Save the verified values.
3. Associate the reading with the currently logged-in farmer.
4. Save the timestamp.
5. Use the existing location/map functionality if already available in the application.
6. Store the original scan image if the existing architecture supports image storage.
7. Record whether the data originated from a sensor scan.
8. Update the existing soil monitoring records/dashboard.

Show a success message:

**Sensor data saved successfully.**

---

# 13. SCAN AGAIN

Provide a clear:

**Scan Again**

button.

If the OCR result is poor, the farmer should be able to return to the camera without having to leave the Soil Monitoring feature.

Do not save the previous scan unless the farmer confirms it.

---

# 14. ORIGINAL IMAGE

When practical, preserve the captured sensor-screen image together with the sensor reading.

Example database information:

```text
farmerId
fertility
moisture
ph
temperature
temperatureUnit
sunlight
humidity
timestamp
source
scanImage
```

Set:

```text
source = "sensor_scan"
```

if the existing database structure allows it.

If image storage already exists in the project, integrate with it rather than creating a duplicate system.

---

# 15. EXISTING MANUAL SOIL INPUT

Do NOT remove the existing manual soil monitoring functionality.

The farmer should have two possible methods:

### Method 1

**Enter Manually**

### Method 2

**Scan Sensor**

Example:

```text
Soil Monitoring

[ Scan Sensor ]

[ Enter Manually ]
```

The existing manual input flow must continue working.

---

# 16. UI/UX REQUIREMENTS

Make the feature simple enough for a farmer who may not be technically experienced.

Use:

* Large readable text
* Clear labels
* Large buttons
* Simple icons
* Minimal clutter
* Clear instructions
* Good spacing
* Existing SMARTFARMING color coding
* Existing application theme
* Existing navigation structure

Do NOT redesign unrelated parts of the application.

Do NOT change existing color meanings.

For example, if the application already uses specific colors for:

* Healthy
* Warning
* Disease
* Soil status
* Weather warnings

preserve those meanings.

---

# 17. ERROR HANDLING

Handle these situations gracefully.

### Camera permission denied

Show:

**Camera permission is required to scan the sensor display.**

Provide an option to open camera permissions.

### No sensor screen detected

Show:

**Sensor display not detected.**

Tips:

* Move closer.
* Keep the display inside the frame.
* Improve lighting.
* Avoid reflections.

### OCR failed

Show:

**Unable to read the sensor display.**

Buttons:

**Try Again**

**Enter Manually**

### Partial OCR result

Do not discard the entire result.

Show the values that were successfully detected and mark missing fields:

```text
Fertility       ✓ Detected
Moisture        ✓ Detected
pH              ⚠ Check
Temperature     ✓ Detected
Sunlight        ✕ Not detected
Humidity        ✓ Detected
```

The farmer can manually enter the missing value.

---

# 18. IMPORTANT DATA INTEGRITY RULE

This is critical.

The application must NEVER silently modify sensor readings.

For example, if OCR detects:

```text
Humidity = 36%
```

the application must not automatically change it to:

```text
Humidity = 38%
```

The extracted value must be presented to the farmer exactly as detected.

Any correction must be performed by the farmer.

The final saved value must be the value the farmer reviewed and confirmed.

---

# 19. FARMER EXPERIENCE FLOW

Implement this complete flow:

```text
Farmer Dashboard
       ↓
Soil Monitoring
       ↓
Scan Sensor
       ↓
Camera Opens
       ↓
Capture Sensor Screen
       ↓
Image Processing
       ↓
LCD/OCR Detection
       ↓
Extract Sensor Values
       ↓
Review Sensor Data
       ↓
Farmer Checks Values
       ↓
 ┌───────────────┐
 │ Values Correct│
 └───────┬───────┘
         ↓
 Confirm & Save
         ↓
 Validate
         ↓
 Save to Database
         ↓
 Update Soil Monitoring
         ↓
 Success Message
```

If incorrect:

```text
Review Sensor Data
       ↓
Edit Value
       ↓
Confirm & Save
```

If the scan is poor:

```text
Review Sensor Data
       ↓
Scan Again
       ↓
Camera
```

---

# 20. IMPLEMENTATION REQUIREMENTS

Before modifying the project:

1. Inspect the existing Flutter project structure.
2. Identify the current Farmer Side Soil Monitoring screens.
3. Identify the existing database/service/repository architecture.
4. Identify the existing authentication and farmer ID system.
5. Identify existing camera/image dependencies.
6. Identify existing OCR/ML dependencies.
7. Reuse existing components whenever possible.

Do NOT create duplicate services, models, repositories, or database collections if equivalent functionality already exists.

Follow the existing project architecture and coding conventions.

---

# 21. IMPORTANT: DO NOT BREAK EXISTING FEATURES

This is an existing capstone system.

Therefore:

* Do not remove existing features.
* Do not rewrite unrelated screens.
* Do not break existing navigation.
* Do not change existing authentication.
* Do not change existing database structures unnecessarily.
* Do not remove manual soil monitoring.
* Do not break the Admin Side.
* Do not break existing farmer records.
* Do not break existing weather functionality.
* Do not break existing disease detection.
* Do not change existing color coding.
* Do not introduce unnecessary dependencies.

Make the scanner an integrated feature of the existing system.

---

# 22. ADMIN SIDE INTEGRATION

If the existing SMARTFARMING system already synchronizes farmer soil monitoring data with the Admin Side, ensure that scanned sensor readings follow the same data flow.

When a farmer saves a verified sensor reading, the Admin Side should be able to receive/display the same verified values through the existing system.

Example:

```text
Farmer
   ↓
Scan Sensor
   ↓
OCR
   ↓
Farmer Verification
   ↓
Confirmed Sensor Data
   ↓
Database
   ↓
Admin Soil Monitoring
```

The Admin Side must receive the **final farmer-confirmed values**, not an unverified OCR result.

---

# 23. FINAL ACCEPTANCE CRITERIA

The implementation is considered complete only when:

* [ ] Farmer can access Soil Monitoring.
* [ ] Farmer can choose Scan Sensor.
* [ ] Camera opens correctly.
* [ ] Farmer can capture the sensor screen.
* [ ] Application can locate/crop the LCD display.
* [ ] Application can recognize digital/LCD numbers.
* [ ] Fertility is extracted.
* [ ] Moisture is extracted.
* [ ] pH is extracted.
* [ ] Temperature is extracted.
* [ ] Temperature unit is preserved.
* [ ] Sunlight is extracted.
* [ ] Humidity is extracted.
* [ ] Extracted data appears in a review screen.
* [ ] Every value is editable.
* [ ] Low-confidence values are identified where possible.
* [ ] Farmer can scan again.
* [ ] Farmer can manually enter missing values.
* [ ] Data is NOT automatically saved after scanning.
* [ ] Farmer must explicitly confirm before saving.
* [ ] Sensor data is validated before saving.
* [ ] Confirmed data is saved to the existing database.
* [ ] Data is associated with the correct farmer.
* [ ] Timestamp is recorded.
* [ ] Existing Admin Side synchronization continues working.
* [ ] Existing manual soil input continues working.
* [ ] Existing SMARTFARMING features remain functional.

## FINAL INSTRUCTION

First inspect the existing project and determine the correct files, screens, models, services, database collections, and dependencies that should be modified.

Then implement the feature using the project's existing architecture.

Do not create a separate standalone demo.

Build this as a production-ready feature inside the existing SMARTFARMING Farmer Side.

Prioritize **accuracy, farmer verification, data integrity, simplicity, and compatibility with the existing capstone system.**
