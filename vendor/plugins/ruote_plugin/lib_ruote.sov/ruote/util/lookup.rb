#--
# Copyright (c) 2005-2011, John Mettraux, jmettraux@gmail.com
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# Made in Japan.
#++


module Ruote

  #   h = { 'a' => { 'b' => [ 1, 3, 4 ] } }
  #
  #   p Ruote.lookup(h, 'a.b.1') # => 3
  #
  def Ruote.lookup(collection, key, container_lookup=false)

    return collection if key == '.'

    key, rest = pop_key(key)
    value = fetch(collection, key)

    return [ key, collection ] if container_lookup && rest.size == 0
    return [ rest.first, value ] if container_lookup && rest.size == 1
    return value if rest.size == 0
    return nil if value == nil

    lookup(value, rest, container_lookup)
  end

  #   h = { 'customer' => { 'name' => 'alpha' } }
  #
  #   Ruote.set(h, 'customer.name', 'bravo')
  #
  #   h #=> { 'customer' => { 'name' => 'bravo' } }
  #
  def Ruote.set(collection, key, value)

    k, c = lookup(collection, key, true)

    if c
      k = k.to_i if c.is_a?(Array)
      c[k] = value
    else
      collection[key] = value
    end
  end

  #   h = { 'customer' => { 'name' => 'alpha', 'rank' => '1st' } }
  #   r = Ruote.unset(h, 'customer.rank')
  #
  #   h # => { 'customer' => { 'name' => 'alpha' } }
  #   r # => '1st'
  #
  def Ruote.unset(collection, key)

    k, c = lookup(collection, key, true)

    if c.nil?
      collection.delete(key)
    elsif c.is_a?(Array)
      c.delete_at(Integer(k)) rescue nil
    elsif c.is_a?(Hash)
      c.delete(k)
    else
      nil
    end
  end

  protected # well...

  # Pops the first key in a path key.
  #
  #   Ruote.pop_key('a.b.c') # => 'a'
  #   Ruote.pop_key('1.2.3') # => 1
  #
  # (note the narrowing to an int that happens)
  #
  def Ruote.pop_key(key)

    ks = key.is_a?(String) ? key.split('.') : key

    [ narrow_key(ks.first), ks[1..-1] ]
  end

  # Attempts at turning a key into an integer, if it fails returns the
  # original key.
  #
  def Ruote.narrow_key(key)

    Integer(key) rescue key
  end

  # Given a collection and a key returns the corresponding value
  #
  #   Ruote.fetch([ 12, 13, 24 ], 1) # => 13
  #   Ruote.fetch({ '1' => 13 }, 1) # => 13
  #   Ruote.fetch({ 1 => 13 }, 1) # => 13
  #
  def Ruote.fetch(collection, key)

    value = (collection[key] rescue nil)

    if value == nil and key.is_a?(Fixnum)
      (collection[key.to_s] rescue nil)
    else
      value
    end
  end
end

