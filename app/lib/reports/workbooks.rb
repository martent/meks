module Reports
  class Workbooks
    class << self
      def rates_formula(rates = [])
        rates.compact!
        # =SUM() is not valid in Excel
        return 0 if rates.blank?
        "=SUM(#{rates.join('+')})"
      end

      def days_amount_formula(days_and_amount = [])
        return 0 if days_and_amount.blank?
        calculation = days_and_amount.map do |da|
          days   = da[:days]   || 0
          amount = da[:amount] || 0
          "#{days}*#{amount}"
        end
        return 0 if calculation.empty?
        "=(#{calculation.join('+')})"
      end
    end

    def initialize(options = {})
      @filename   = options[:filename] || 'Utan titel.xlsx'
      @from       = options[:from]     || default_date_range[:from]
      @to         = options[:to]       || default_date_range[:to]
      @sheet_name = format_sheet_name
    end

    def create
      axlsx     = Axlsx::Package.new
      @workbook = axlsx.workbook
      @sheet    = @workbook.add_worksheet(name: @sheet_name)
      @style    = Style.new(axlsx)

      fill_sheet

      axlsx.serialize File.join(Rails.root, 'reports', @filename)
    end

    def header_row
      columns.map do |cell|
        { title: cell[:heading], tooltip: cell[:tooltip] }
      end
    end

    def data_rows
      records.each_with_index.map do |refugee, i|
        columns(refugee, i).map do |cell|
          cell
        end
      end
    end

    def format_sheet_name
      @from && @to ? "#{@from.to_date}–#{@to.to_date}" : 'Inget intervall'
    end

    def i18n_name(name)
      I18n.t("simple_form.labels.#{name}", default: name)
    end

    protected

    def fill_sheet
      add_header_row
      add_data_rows
    end

    def add_header_row
      headings = @sheet.add_row(
        header_row.map { |heading| i18n_name(heading[:title]) },
        style: @style.heading
      )
      add_header_tooltips(headings)
    end

    def add_header_tooltips(headings)
      # Add tooltip to given col headings
      # Axlsx has a bug for newer version of Excel comments
      #   so we use a workaround with validation tooltips activated when
      #   the user selects a cell. No real validation is performed.
      headings.cells.each_with_index do |cell, i|
        tooltip = header_row[i][:tooltip]
        next unless tooltip

        cell.style = @style.heading_with_tooltip
        @sheet.add_data_validation(
          cell.r,
          type: :textLength,
          style: @style.heading_with_tooltip,
          showInputMessage: true,
          promptTitle: 'Kolumnförklaring:',
          prompt: tooltip
        )
      end
    end

    def add_data_rows
      # xlsx data rows
      # records can be and active record enumerator or an array of records
      data_rows.each do |row|
        @sheet.add_row(
          row.map { |cell| cell[:query] },
          # :style and :type creates invalid xlsx file if the record set is large
          # style: row.map { |cell| cell_style(cell[:style]) },
          # types: row.map { |cell| cell_type(cell[:type]) }
        )
      end
      add_last_row
    end

    def add_last_row
      data_rows = records.size
      return if data_rows.zero?

      row = last_row(data_rows + 1)
      @sheet.add_row(
        row.map { |cell| cell }
      )
    end

    def cell_style(style)
      style ||= :normal
      @style.send(style)
    end

    def cell_type(type = :string)
      type
    end

    def records
      raise NotImplementedError, "Implement #{__method__} method in your #{self.class.name} subclass"
    end

    def last_row(_row_number)
      []
    end

    def columns(*_args)
      raise NotImplementedError, "Implement #{__method__} method in your #{self.class.name} subclass"
    end

    def default_date_range
      { from: Date.new(0), to: Date.today }
    end
  end
end
