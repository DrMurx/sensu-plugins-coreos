#! /usr/bin/env ruby

require 'sensu-plugin/check/cli'
require 'dbus'

$status_map = {
  "UPDATE_STATUS_IDLE" => {
    :sensu_severity => 0,
    :message_template => "No update available",
  },
  "UPDATE_STATUS_CHECKING_FOR_UPDATE" => {
    :sensu_severity => 0,
    :message_template => "Checking for update",
  },
  "UPDATE_STATUS_UPDATE_AVAILABLE" => {
    :sensu_severity => 1,
    :message_template => "Update available (%s)",
  },
  "UPDATE_STATUS_DOWNLOADING" => {
    :sensu_severity => 1,
    :message_template => "Downloading (%s)",
  },
  "UPDATE_STATUS_VERIFYING" => {
    :sensu_severity => 1,
    :message_template => "Downloading (%s)",
  },
  "UPDATE_STATUS_FINALIZING" => {
    :sensu_severity => 1,
    :message_template => "Downloading (%s)",
  },
  "UPDATE_STATUS_UPDATED_NEED_REBOOT" => {
    :sensu_severity => 2,
    :message_template => "Reboot required! (%s)",
  },
  "UPDATE_STATUS_REPORTING_ERROR_EVENT" => {
    :sensu_severity => 2,
    :message_template => "Unknown error reported",
  },
}

class CheckCoreosUpdate < Sensu::Plugin::Check::CLI

  def initialize
    @bus = DBus::SystemBus.instance

    @coreos_update_service = @bus.service("com.coreos.update1")
    @coreos_update_object = @coreos_update_service.object("/com/coreos/update1")
    @update_manager = @coreos_update_object["com.coreos.update1.Manager"]
  end

  def run
    status = get_coreos_update_status
    case status[:sensu_severity]
    when 0
      ok status[:message]
    when 1
      warning status[:message]
    when 2
      critical status[:message]
    end
  end

  private
  def get_coreos_update_status
    status = map_to_object("GetStatus", @update_manager.GetStatus)
    status.merge! $status_map[status[:current_operation]]
    severity = status[:sensu_severity]
    status[:message] = status[:message_template] % status[:new_version]
    status
  end

  def map_to_object(method, a)
    o = {}
    @update_manager.methods[method].rets.map.with_index do |ret, i|
      o[ret.name.to_sym] = a[i]
    end
    o
  end

end
