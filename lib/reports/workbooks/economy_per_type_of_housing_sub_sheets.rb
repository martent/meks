module Reports
  class EconomyPerTypeOfHousingSubSheets < Workbooks
    def initialize(options = {})
      super(options)
      @axlsx           = options[:axlsx]
      @type_of_housing = options[:type_of_housing]
      @sheet_name      = @type_of_housing.name
    end

    def create
      @workbook = @axlsx.workbook
      @sheet    = @workbook.add_worksheet(name: @sheet_name)
      @style    = Style.new(@axlsx)

      fill_sheet
    end

    def records
      Refugee.per_type_of_housing(@type_of_housing, from: @from, to: @to)
    end

    def columns(refugee = Refugee.new, i = 0)
      row = i + 2
      [
        {
          heading: 'Dossiernumber',
          query: refugee.dossier_number
        },
        {
          heading: 'Budgeterad kostnad',
          query: self.class.costs_formula(refugee.placements_costs_and_days(from: @from, to: @to))
        },
        {
          heading: 'Förväntad schablon',
          query: refugee.expected_rate
        },
        {
          heading: 'Avvikelse',
          query: "=C#{row}-B#{row}"
        },
        {
          heading: 'Utbetald schablon',
          query: self.class.payments_formula(refugee.amount_and_days(from: @from, to: @to))
        },
        {
          heading: 'Avvikelse',
          query: "=E#{row}-C#{row}"
        }
      ]
    end

    def last_row(row_number)
      [
        '',
        "=SUM(B2:B#{row_number})",
        "=SUM(C2:C#{row_number})",
        "=SUM(D2:D#{row_number})",
        "=SUM(E2:E#{row_number})",
        "=SUM(F2:F#{row_number})"
      ]
    end
  end
end
