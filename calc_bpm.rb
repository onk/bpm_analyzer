# 全体的に
# http://hp.vector.co.jp/authors/VA046927/tempo/tempo.html
# のロジックを実装

FRAME_SIZE = 512
MIN_BPM = 60
MAX_BPM = 300

Bundler.require

# wav ファイル読み込み
# http://shokai.org/blog/archives/5408
def read_wav(filename)
  f = open(filename)
  format = WavFile::readFormat(f)
  dataChunk = WavFile::readDataChunk(f)
  f.close

  puts format
  bit = 's*' if format.bitPerSample == 16 # int16_t
  bit = 'c*' if format.bitPerSample == 8  # signed char
  dataChunk.data.unpack(bit) # read binary
end

def split_frame(data, frame_size)
  data = data.take(data.size - data.size % frame_size) # 余りフレームを切り捨てる
  data.each_slice(frame_size)
end

# 音量を求める (振幅二乗和
def calc_vols(data, frame_size)
  data.map {|arr| Math.sqrt(arr.map{|v| v**2 }.inject(:+) / frame_size) }
end

# 音量の増加量(減少は 0 とする)
# 音量の減少の仕方は増加の仕方と比較して周期性がないため
def calc_vol_diff(data)
  data.map.with_index { |n, i| [data[i] - data[i - 1], 0].max }
end

def cals_match_bpm(data, bpm)
  size = data.size
  cos_sum = 0;
  sin_sum = 0;
  hz = bpm / 60.0;
  sampling_rate_per_frame = 44100 / 512

  data.each_with_index do |n, i|
    # TODO: window 関数を使っていない
    cos_sum += n * Math.cos(2 * Math::PI * hz * i / sampling_rate_per_frame);
    sin_sum += n * Math.sin(2 * Math::PI * hz * i / sampling_rate_per_frame);
  end

  Math.sqrt((cos_sum/size)**2 + (sin_sum/size)**2)
end

def calc_all_match(data)
  Hash[[*MIN_BPM..MAX_BPM].map {|bpm| [bpm, cals_match_bpm(data, bpm)] }]
end

def get_top_10(data)
  Hash[data.sort_by{|bpm, rate| -rate }.take(10)]
end

def main(filename = "input.wav")
  # wavファイル読み込み
  data = read_wav(filename)
  # wavファイルを一定時間(以下フレーム)ごとに区切る。
  data = split_frame(data, FRAME_SIZE)
  # フレームごとの音量を求める。
  vols = calc_vols(data, FRAME_SIZE)
  # 隣り合うフレームの音量の増加量を求める。
  vol_diff = calc_vol_diff(vols)
  # 増加量の時間変化の周波数成分を求める。
  all_match = calc_all_match(vol_diff)
  plot("all_match", all_match)
  # 周波数成分のピークを検出する。
  top_10 = get_top_10(all_match)
  return top_10
  # ピークの周波数からテンポを計算する。
  # ピークの周波数成分の位相から拍の開始位置を計算する。
end

def plot(info, data)
  g = Gruff::Line.new
  g.font = "/Library/Fonts/Osaka.ttf"
  if data.is_a?(Hash)
    g.data(info, data.values)
    label_hash = {}
    data.keys.each_with_index do |l, i|
      next unless i % 30 == 0
      label_hash[i] = l.to_s
    end
    g.labels = label_hash
  else
    g.data(info, data)
  end
  g.write("public/output.png")
end

main if __FILE__ == $0

