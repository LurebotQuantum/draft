# coding: utf-8
# ----------------------------------------------------------------------------
# This file denotes the basic form of input arguments which lurebot accepts
# and processes. It was strongly inspired by PowerShell.
# ----------------------------------------------------------------------------
# Usage: ruby params.rb <command> [options]...
#   <command> is any string
#   [options] may be in these forms:
#     --option=value -opt=val
#     --option value -opt val
#      /option=value /opt val
#     --switch       -s

class Params
  attr_accessor :params, :result
  def initialize
    @params = []
    @result = {}
  end
  FIELDS = %i(default alias omit)
  %i(switch string int).each do |meth|
    define_method meth do |name, **options|
      @params << [meth, name, *options.values_at(*FIELDS)]
    end
  end
  def before_run
    @lookups = {}
    @params.each do |xs|
      case xs[0]
      when :switch then xs[2] ||= false
      when :string then xs[2] ||= ''
      when :int    then xs[2] ||= 0
      end
      unless Array === xs[3]
        xs[3] = [xs[3]].compact
      end
      xs[4] ||= false
      @lookups[[xs[1], *xs[3]].map &:to_s] = [xs[2], xs[4], xs[0] == :switch]
    end
  end
  def run argv=ARGV
    before_run
    @command = argv.shift
    seq = []
    while a = argv.shift
      if a.start_with? '-', '/'
        b = a.sub /^(-+|\/)/, ''
        if a.include? '='
          seq << (b.split '=')
        elsif @lookups.find { |k, v| k.include? b and v[2] }
          seq << [b, true]
        else
          seq << [b, argv.shift]
        end
      else
        seq << a
      end
    end
    map = {}
    while a = seq.shift
      flag = false
      if Array === a
        map[a[0]] = a[1]
        @lookups.delete_if do |k, v|
          next false if flag
          if k.include? a[0].to_s
            map.delete a[0]
            map[k[0]] = a[1] || v[0]
            flag = true
          end
        end
      else
        @lookups.delete_if do |k, v|
          next false if flag
          if v[1]
            map[k[0]] = a
            flag = true
          end
        end
      end
    end
    @result = map
  end
  alias to_h result
  def inspect
    "#<Params #@command #{@result.map { |e| e.join('=') }.join(' ')}>"
  end
  def [] key
    result[key.to_s]
  end
end

def params &blk
  @params ||= Params.new
  if block_given?
    @params.instance_eval &blk
    @params.run
  else
    @params
  end
end

params {
  string :option, alias: :opt, omit: true
  switch :switch, alias: :s
}

pp params
