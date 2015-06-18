class BasicObject
  ts '#== / BasicObject -> Boolean'
end

class TestIf

  ts '#initialize / -> unit'
  def initialize
    @state = 'unknown'
  end

  ts '#open / -> String'
  def open
    @state = 'open'
  end

  ts '#close / -> String'
  def close
    @state = 'close'
  end

  ts '#set_state / String -> String'
  def set_state(state)
    @state = state
  end

  ts '#open / -> String'
  def open
    if @state == 'open'
      @state
    else
      'not_open'
    end
  end
end
