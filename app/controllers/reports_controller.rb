class ReportsController < ApplicationController
  skip_authorize_resource
  skip_authorization_check
  before_action { authorize! :generate, :reports }

  include ReportGenerator

  def index
    @homes = Home.order(:name)
    @pre_generated_reports = pre_generated_reports
  end

  def downloads
    filename = find_report(params[:id].to_i)['filename']
    send_file report_filepath(filename), type: :xlsx, disposition: 'attachment', filename: filename
  end

  def placements
    records = Placement.includes(
      :refugee, :home, :moved_out_reason,
      refugee: [:countries, :languages, :ssns, :dossier_numbers,
                :gender, :homes, :placements, :municipality,
                :relateds, :inverse_relateds, :deregistered_reason],
      home: [:languages, :type_of_housings, :placements,
             :owner_type, :target_groups, :languages])

    # Been on the home during a given range
    if params[:placements_from].present? && params[:placements_to].present?
      records = records.where(
        '(moved_out_at >= ? or moved_out_at is null)
         and moved_in_at <= ?',
        params[:placements_from],
        params[:placements_to])
    end

    # Selected one home or all
    if params[:placements_home_id].present? && params[:placements_home_id].reject(&:empty?).present?
      records = records.where(home_id: params[:placements_home_id])
    end

    # Only overlapping placements in time per refugee
    if params[:placements_selection] == 'overlapping'
      records = Placement.overlapping_by_refugee(params)
    end

    # Filter out each placement's refugee's other placements that do not fall within the given range.
    #   Used for "All homes" column for each placement. The relation is:
    #   placement (the record) => refugee => all that refugee's placements within range
    refugees = records.map { |placement| placement.refugee }.uniq
    refugees.each do |refugee|
      refugee.placements = refugee.placements.reject do |placement|
        false if placement.moved_in_at <= params[:placements_to].to_date && (placement.moved_out_at.nil? || placement.moved_out_at >= params[:placements_from].to_date)
      end
    end

    xlsx = generate_xlsx(:placements, records)
    send_xlsx xlsx, 'Placeringar'
  end

  def refugees
    records = Refugee.includes(
      :countries, :languages, :ssns, :dossier_numbers,
      :gender, :homes, :placements, :municipality,
      :relateds, :inverse_relateds, :deregistered_reason, :current_placements,
      placements: [:home])

    if params[:refugees_registered_from].present? && params[:refugees_registered_to].present?
      records = records.where(registered: params[:refugees_registered_from]..params[:refugees_registered_to])
    end

    query = [(params[:refugees_born_after]..params[:refugees_born_before])]
    query << nil if params[:refugees_include_without_date_of_birth]
    if params[:refugees_born_after].present? && params[:refugees_born_before].present?
      records = records.where(date_of_birth: query)
    end

    if params[:refugees_asylum].present?
      query = []
      if params[:refugees_asylum].include? 'put'
        query << 'refugees.residence_permit_at is not null'
      end
      if params[:refugees_asylum].include? 'tut'
        query << 'refugees.temporary_permit_starts_at is not null'
      end
      if params[:refugees_asylum].include? 'municipality'
        query << 'refugees.municipality_id is not null'
      end
      records = records.where(query.join(' or '))
    end

    xlsx = generate_xlsx(:refugees, records)
    send_xlsx xlsx, 'Ensamkommand-barn'
  end

  def homes
    records = Home.includes(
      :placements, :type_of_housings,
      :owner_type, :target_groups, :languages)

    if params[:homes_owner_type].present?
      records = records.where(owner_type: params[:homes_owner_type])
    end

    if params[:homes_free_seats] == 'with'
      records = records.each.reject { |r| r.free_seats <= 0 }
    end

    xlsx = generate_xlsx(:homes, records)
    send_xlsx xlsx, 'Boenden'
  end

  private

  def pre_generated_reports
    APP_CONFIG['pre_generated_reports'].each do |report|
      filepath = report_filepath(report['filename'])

      if File.exist?(filepath)
        report.merge!(
          filetime: File.mtime(filepath).localtime,
          filesize: File.size(filepath)
        )
      end
    end
  end

  def report_filepath(filename)
    File.join(Rails.root, 'reports', filename)
  end

  def find_report(id)
    APP_CONFIG['pre_generated_reports'].detect { |r| r['id'] == id.to_i }
  end

  def numshort_date(date)
    I18n.l(date, format: :numshort) unless date.nil?
  end
end
