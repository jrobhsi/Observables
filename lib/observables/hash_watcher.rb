module Observables
  module HashWatcher
    include Observables::Base

    MODIFIER_METHODS = :replace, :merge!, :update
    REMOVE_METHODS =   :clear, :delete, :delete_if, :reject!, :shift

    #[]= can either be an add method or a modifier method depending on
    #if the previous key exists
    def []=(key,val)
      change_type = keys.include?(key) ? :modified : :added
      changes = changes_for(change_type,:[]=,key,val)
      changing(change_type,:trigger=>:[]=, :changes=>changes) {super}
    end
    alias :store :[]=

    override_mutators :modified=>MODIFIER_METHODS,
                      :removed=>REMOVE_METHODS

    def changes_for(change_type, trigger_method, *args, &block)
      prev = self.dup
      if change_type == :added
        Proc.new {{:added=>[args]}}
      elsif change_type == :removed
        case trigger_method
          when :clear then Proc.new{{:removed=>prev.to_a}}
          when :delete then Proc.new{{:removed=>[[args[0],prev[args[0]]]]}}
          # API change between 1.8.7 and 1.9.3: select returns hash instead of array
          when :delete_if, :reject! then Proc.new{{:removed=>prev.select(&block).to_a}}
          when :shift then Proc.new { {:removed=>[prev.keys[0],prev.values[0]]}}
        end
      else
        case trigger_method
          when :[]= then Proc.new{{:removed=>[[args[0],prev[args[0]]]],:added=>[args]}}
          when :replace then Proc.new{{:removed=>prev.to_a, :added=>args[0].to_a}}
          when :merge!, :update then Proc.new{{:removed=>prev.select{|k,_|args[0].keys.include?(k)}.to_a,:added=>args[0].to_a}}
        end
      end
    end
  end
end