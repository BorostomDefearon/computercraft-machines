function getDeviceSide(deviceType)
  local lstSides = {"left","right","up","down","front","back"};
  for i, side in pairs(lstSides) do
    if (peripheral.isPresent(side)) then
      if (peripheral.getType(side) == string.lower(deviceType)) then
        return side;
      end
    end
  end
  return nil;
end