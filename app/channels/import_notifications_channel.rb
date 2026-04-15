# frozen_string_literal: true

class ImportNotificationsChannel < ApplicationCable::Channel
  def subscribed
    stream_from "import_status_#{current_user.id}"
  end

  def unsubscribed
    stop_all_streams
  end
end
