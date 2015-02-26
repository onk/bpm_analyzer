Bundler.require

f = open("input.wav")
format = WavFile::readFormat(f)
dataChunk = WavFile::readDataChunk(f)
f.close

bit = "s*" # int16_t
wavs = dataChunk.data.unpack(bit) # read binary

g = Gruff::Line.new
g.font = "/Library/Fonts/Osaka.ttf"
g.data("input.wav", wavs)
g.write("output.png")
