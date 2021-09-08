
print('AppEngine Version: ' .. Engine.getVersion())

--Start of Function and Event Scope---------------------------------------------

--@readOCR(img:Image,handleFile:string)
local function readOCR(img, handleFile)
  -- Creating HALCON handle
  local hdevOCRReader = Halcon.create()
  -- Loading OCRReader.hdvp script into HALCON handle
  hdevOCRReader:loadProcedure('resources/OCRReader.hdvp')

  -- Setting the image and control input parameters of the HALCON function OCRReader.hdvp
  hdevOCRReader:setImage('TestImage', img)
  hdevOCRReader:setString('OCRHandleFilename', handleFile)

  -- Executing the loaded function
  local result = hdevOCRReader:execute()

  -- Retrieving result and return values of OCRReader.hdvp,
  -- including the labels and the positions of the segmented regions
  local labels = result:getStringArray('Labels')
  local xCoords = result:getDoubleArray('RegionXCoords')
  local yCoords = result:getDoubleArray('RegionYCoords')

  print('Reading finished')
  return labels, xCoords, yCoords
end

--Declaration of the 'main' function as an entry point for the event loop
local function main()
  local ocrHandle = 'ocrhandle.ocm'
  --Checking if trained OCR handle exists
  local ocrHandleFound
  if File.exists('public/' .. ocrHandle) then
    ocrHandleFound = true
    print(ocrHandle .. ' found in public AppData')
  elseif (File.exists('resources/' .. ocrHandle)) then
    File.copy('resources/' .. ocrHandle, 'public/' .. ocrHandle)
    ocrHandleFound = true
    print(ocrHandle .. ' found in resources')
  else
    ocrHandleFound = false
    print(ocrHandle .. ' not found. Run OCRTraining_HALCON to get trained handle')
  end

  if ocrHandleFound then
    -- Loading test image
    local testImage = Image.load('resources/TestImage.bmp')
    local viewer = View.create("viewer2D1")

    -- Reading characters using OCR handle in testImage
    -- Getting labels which denote the classified characters for each segmented region
    -- in the testImage.
    local labels,
      xCoords,
      yCoords = readOCR(testImage, ocrHandle)

    -- Visualize labels and testImage
    local labelsSize = table.maxn(labels)

    viewer:clear()
    local imageID = viewer:addImage(testImage)
    viewer:present()

    for i = 1, labelsSize do
      local textDeco = View.TextDecoration.create()
      textDeco:setSize(30)
      -- show all characters on a straight line ignoring offsets and deviations
      -- in character positions to previous -20 < pos < 20
      if (i > 1 and math.abs(yCoords[i] - yCoords[i - 1]) < 20) then
        yCoords[i] = yCoords[i - 1]
      end
      textDeco:setPosition(xCoords[i], yCoords[i] + 55)
      viewer:addText(labels[i], textDeco, nil, imageID)
    end
    viewer:present()
    print('See 2D viewer for Result')
  end
  print('App finished.')
end
--The following registration is part of the global scope which runs once after startup
--Registration of the 'main' function to the 'Engine.OnStarted' event
Script.register('Engine.OnStarted', main)

--End of Function and Event Scope-----------------------------------------------
