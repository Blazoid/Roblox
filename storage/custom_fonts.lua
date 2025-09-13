--// Example: TextLabel.FontFace = custom_fonts[font name]
if not getgenv().custom_fonts then getgenv().custom_fonts = {} end
getgenv().custom_fonts = {
    Graph-35 = {},
    Minecraftia = {},
    ProggyCleanTT = {},
    SmallestPixel = {},
    Templeos = {},
    ProggyTiny = {},
	Trash_Bag = {}
}
do
    function custom_fonts.Trash_Bag:Register_Font(Name, Weight, Style, Asset)
        if not isfolder('Fonts') then makefolder('Fonts') end
        local asset = 'Fonts/' .. Asset.Id
        local font = 'Fonts/' .. Name .. '.font'
        if not isfile(asset) then writefile(asset, Asset.Font) end
        writefile(font,game:GetService('HttpService'):JSONEncode({name = Name,faces = {{name = 'Regular',weight = Weight,style = Style,assetId = getcustomasset(asset)}}}))
        return getcustomasset(font)
    end
    custom_fonts = {
        Graph35 = Font.new(custom_fonts.Trash_Bag:Register_Font('Graph35', 400, 'Regular', {Id = 'Graph35.ttf',Font = crypt.base64.decode(game:HttpGet('https://raw.github.com/Blazoid/Trash/main/Graph_35'))})),
        Minecraftia = Font.new(custom_fonts.Trash_Bag:Register_Font('Minecraftia', 400, 'Regular', {Id = 'Minecraftia.ttf',Font = crypt.base64.decode(game:HttpGet('https://raw.github.com/Blazoid/Trash/main/Minecraftia'))})),
        ProggyCleanTT = Font.new(custom_fonts.Trash_Bag:Register_Font('ProggyCleanTT', 400, 'Regular', {Id = 'ProggyCleanTT.ttf',Font = crypt.base64.decode(game:HttpGet('https://raw.github.com/Blazoid/Trash/main/ProggyCleanTT'))})),
        SmallestPixel = Font.new(custom_fonts.Trash_Bag:Register_Font('SmallestPixel', 400, 'Regular', {Id = 'SmallestPixel.ttf',Font = crypt.base64.decode(game:HttpGet('https://raw.github.com/Blazoid/Trash/main/Smallest_Pixel'))})),
        Templeos = Font.new(custom_fonts.Trash_Bag:Register_Font('Templeos', 400, 'Regular', {Id = 'Templeos.ttf',Font = crypt.base64.decode(game:HttpGet('https://raw.github.com/Blazoid/Trash/main/Templeos'))})),
        ProggyTiny = Font.new(custom_fonts.Trash_Bag:Register_Font('ProggyTiny', 400, 'Regular', {Id = 'ProggyTiny.ttf',Font = crypt.base64.decode(game:HttpGet('https://raw.github.com/Blazoid/Trash/main/ProggyTiny'))})),
    }
end

