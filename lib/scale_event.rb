class ScaleEvent
  def initialize(app, type)
  	@timestamp = Time.now.to_i
  	@type = type
  	@instances_count = app.total_instances
  end

  def type
  	"Add Instance"
  end

  attr_reader :instances_count, :timestamp
end