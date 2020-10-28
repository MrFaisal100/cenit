class Script
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name
  field :description, type: String
  field :code, type: String

  validates_presence_of :name, :description

  before_save do
    errors.add(:code, "can't be blank") if code.blank?
    abort_if_has_errors
  end

  def parameters
    []
  end

  def run(task)
    task.instance_eval(code)
  end
end
