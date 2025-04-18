class RobinhoodDjb2HashMap
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

    index = djb2(key) % @capacity
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

    index = djb2(key) % @capacity
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

    index = djb2(key) % @capacity
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

  def djb2(str)
    hash = 5381
    str.each_byte { |b| hash = ((hash << 5) + hash) + b }
    hash & 0x7fffffff
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
  data = [["apple", 10], ["banana", 20], ["orange", 30], ["grape", 40]]
  map = RobinhoodDjb2HashMap.new(data)

  puts map.get("apple")    # => 10
  puts map.get("banana")   # => 20
  puts map.get("orange")   # => 30
  puts map.get("grape")    # => 40

  map.put("melon", 50)
  puts map.get("melon")    # => 50

  map.delete("banana")
  puts map.get("banana")   # => nil

  puts "--- map status ---"
  p map
end
