class AuditorObserver < ActiveRecord::Observer
  observe :product, :document

  def after_save(record)
    payload_json = record.to_json(:except => [:id,:created_at, :updated_at])
    payload_type = record.class
    payload_id = record.id
    modified_attributes = record.changed.join(',')
    begin
      current_user_id = UserSession.find.record.id
    rescue
      current_user_id = Admin.first.id
    end

    Audit.create(:payload_json => payload_json, :payload_type => payload_type, :payload_id => payload_id, :modified_attributes => modified_attributes, :user_id => current_user_id)
  end

end
