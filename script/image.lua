
-- Autoloads all images to memory

image = {}

love.graphics.setDefaultFilter("nearest", "nearest")

local function getFiles(rootPath, tree)
  tree = tree or {}
  lfs = love.filesystem
  filesTable = lfs.getDirectoryItems(rootPath)
  
  for i,v in ipairs(filesTable) do
    path = rootPath.."/"..v
    if lfs.getInfo(path).type == "file" then
      tree[#tree+1] = path
    elseif lfs.getInfo(path).type == "directory" then
      fileTree = getFiles(path, tree)
    end
  end
  return tree
end

local imageNames = getFiles("image")

for i = 1, #imageNames do
    path = imageNames[i]
    key = path:sub(7, #path-4)
    image[key] = love.graphics.newImage(path)
end