class RobinhoodMurmurHashMap
  LOAD_FACTOR = 0.75

  PRIMES = [
    53, 97, 193, 389, 769,
    1543, 3079, 6151, 12289, 24593,
    49157, 65521, 90001, 120071, 131071
  ]

  def initialize(data = nil)
    @prepared = false
    @size = 0

    if data.is_a?(Array) && data.all? { |e| e.is_a?(Array) && e.size == 2 }
      prepare(data.map { |k, _| k })
      data.each { |k, v| put(k, v) }
    else
      raise ArgumentError
    end
  end

  def prepare(keys)
    return if @prepared

    estimated_keys = keys.uniq.size
    ideal_capacity = (estimated_keys / LOAD_FACTOR).ceil
    @capacity = next_prime_from_table(ideal_capacity)
    @buckets = Array.new(@capacity)
    @prepared = true
  end

  def put(key, value)
    prepare([key]) unless @prepared

    resize if @size >= @capacity * LOAD_FACTOR

    index = murmur3(key) % @capacity  # djb2 -> murmur3
    probe_distance = 0

    loop do
      bucket = @buckets[index]

      if bucket.nil?
        @buckets[index] = [key, value, probe_distance]
        @size += 1
        return
      elsif bucket[0] == key
        @buckets[index][1] = value
        return
      elsif bucket[2] < probe_distance
        key, value, probe_distance, @buckets[index] = bucket[0], bucket[1], bucket[2], [key, value, probe_distance]
      end

      index = (index + 1) % @capacity
      probe_distance += 1
    end
  end

  def get(key)
    return nil unless @prepared

    index = murmur3(key) % @capacity  # djb2 -> murmur3
    probe_distance = 0

    loop do
      bucket = @buckets[index]
      return nil if bucket.nil?
      return bucket[1] if bucket[0] == key
      break if bucket[2] < probe_distance

      index = (index + 1) % @capacity
      probe_distance += 1
    end

    nil
  end

  def delete(key)
    return unless @prepared

    index = murmur3(key) % @capacity  # djb2 -> murmur3
    probe_distance = 0

    loop do
      bucket = @buckets[index]
      return if bucket.nil?
      if bucket[0] == key
        @buckets[index] = nil
        @size -= 1
        rehash_from(index)
        return
      end
      break if bucket[2] < probe_distance

      index = (index + 1) % @capacity
      probe_distance += 1
    end
  end

  private

  # MurmurHash3 32-bit
  def murmur3(str, seed = 0)
    data = str.bytes
    length = data.length
    h = seed

    c1 = 0xcc9e2d51
    c2 = 0x1b873593

    i = 0
    while i + 4 <= length
      k = data[i] | (data[i+1] << 8) | (data[i+2] << 16) | (data[i+3] << 24)
      i += 4

      k = (k * c1) & 0xffffffff
      k = (k << 15 | k >> 17) & 0xffffffff
      k = (k * c2) & 0xffffffff

      h ^= k
      h = (h << 13 | h >> 19) & 0xffffffff
      h = (h * 5 + 0xe6546b64) & 0xffffffff
    end

    k = 0
    remain = length & 3
    if remain >= 3
      k ^= data[i+2] << 16
    end
    if remain >= 2
      k ^= data[i+1] << 8
    end
    if remain >= 1
      k ^= data[i]
      k = (k * c1) & 0xffffffff
      k = (k << 15 | k >> 17) & 0xffffffff
      k = (k * c2) & 0xffffffff
      h ^= k
    end

    h ^= length
    h ^= h >> 16
    h = (h * 0x85ebca6b) & 0xffffffff
    h ^= h >> 13
    h = (h * 0xc2b2ae35) & 0xffffffff
    h ^= h >> 16

    h & 0x7fffffff  # positivve integer
  end

  def resize
    old_buckets = @buckets.compact
    next_capacity = next_prime_from_table(@capacity * 2)
    @capacity = next_capacity
    @buckets = Array.new(@capacity)
    @size = 0

    old_buckets.each { |k, v, _| put(k, v) }
  end

  def rehash_from(start_index)
    index = (start_index + 1) % @capacity

    while (bucket = @buckets[index])
      @buckets[index] = nil
      @size -= 1
      put(bucket[0], bucket[1])
      index = (index + 1) % @capacity
    end
  end

  def next_prime_from_table(n)
    PRIMES.find { |prime| prime >= n } || PRIMES.last
  end
end


# ==== test ====
if __FILE__ == $0
  data = [["apple", 5], ["banana", 8], ["orange", 10]]
  map = RobinhoodMurmurHashMap.new(data)

  puts map.get("apple")
  puts map.get("banana")
  puts map.get("orange")

  puts "--- map status ---"
  p map
end
