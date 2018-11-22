# Schablonkategori Ankomstbarn 0-17
# See specifications of conditions in app/lib/economy/rates.rb
RSpec.describe 'Rates for arrival_0_17' do
  let(:refugee) { create(:refugee) }

  before(:each) do
    refugee.reload
    create_rate_categories_with_rates

    # Mandatories
    # refugee.registered (defined below)

    # Must not have
    # refugee.citizenship_at (defined below)

    # Count days from the last of the following
    refugee.date_of_birth                              = '2010-01-01'
    refugee.registered                                 = '2018-01-01'

    # Count days to the first of the following occurs
    # refugee.date_of_birth # + 1 year - 1 day (defined above)
    refugee.deregistered                               = nil
    refugee.municipality_placement_migrationsverket_at = '2019-01-01'
    refugee.temporary_permit_starts_at                 = '2019-01-01'
    refugee.residence_permit_at                        = nil
    refugee.citizenship_at                             = nil
  end

  it 'should have correct rate amount and days' do
    rates = Economy::RatesForRefugee.new(refugee, UnitMacros::REPORT_INTERVAL).as_array
    rate = detect_rate_by_amount(rates, UnitMacros::RATES[:arrival_0_17])

    expect(rate[:days]).to eq 91
  end

  it 'should respond to changed registered' do
    refugee.registered = '2018-04-06'

    rates = Economy::RatesForRefugee.new(refugee, UnitMacros::REPORT_INTERVAL).as_array
    rate = detect_rate_by_amount(rates, UnitMacros::RATES[:arrival_0_17])

    expect(rate[:days]).to eq 86
  end

  it 'should respond to changed date_of_birth' do
    refugee.date_of_birth = '2018-04-06'

    rates = Economy::RatesForRefugee.new(refugee, UnitMacros::REPORT_INTERVAL).as_array
    rate = detect_rate_by_amount(rates, UnitMacros::RATES[:arrival_0_17])

    expect(rate[:days]).to eq 86
  end

  it 'should respond to changed deregistered' do
    refugee.deregistered = '2018-04-06'

    rates = Economy::RatesForRefugee.new(refugee, UnitMacros::REPORT_INTERVAL).as_array
    rate = detect_rate_by_amount(rates, UnitMacros::RATES[:arrival_0_17])

    expect(rate[:days]).to eq 5
  end

  it 'should respond to changed municipality_placement_migrationsverket_at' do
    refugee.residence_permit_at = '2018-06-01'

    rates = Economy::RatesForRefugee.new(refugee, UnitMacros::REPORT_INTERVAL).as_array
    rate = detect_rate_by_amount(rates, UnitMacros::RATES[:arrival_0_17])

    expect(rate[:days]).to eq 62
  end

  it 'should respond to temporary_permit_starts_at' do
    refugee.temporary_permit_starts_at = '2018-05-01'

    rates = Economy::RatesForRefugee.new(refugee, UnitMacros::REPORT_INTERVAL).as_array
    rate = detect_rate_by_amount(rates, UnitMacros::RATES[:arrival_0_17])

    expect(rate[:days]).to eq 31
  end

  it 'should respond to residence_permit_at' do
    refugee.residence_permit_at = '2018-05-01'

    rates = Economy::RatesForRefugee.new(refugee, UnitMacros::REPORT_INTERVAL).as_array
    rate = detect_rate_by_amount(rates, UnitMacros::RATES[:arrival_0_17])

    expect(rate[:days]).to eq 31
  end

  it 'should respond to citizenship_at' do
    refugee.citizenship_at = '2018-01-01'

    rates = Economy::RatesForRefugee.new(refugee, UnitMacros::REPORT_INTERVAL).as_array
    rate = detect_rate_by_amount(rates, UnitMacros::RATES[:arrival_0_17])

    expect(rate).to be_nil
  end

  it 'should require registered' do
    refugee.registered = nil

    rates = Economy::RatesForRefugee.new(refugee, UnitMacros::REPORT_INTERVAL).as_array
    rate = detect_rate_by_amount(rates, UnitMacros::RATES[:arrival_0_17])

    expect(rate).to be_nil
  end

  it 'should not have refugee.citizenship_at' do
    refugee.citizenship_at = '2018-01-01'

    rates = Economy::RatesForRefugee.new(refugee, UnitMacros::REPORT_INTERVAL).as_array
    rate = detect_rate_by_amount(rates, UnitMacros::RATES[:arrival_0_17])

    expect(rate).to be_nil
  end

  describe 'deduction of days for placements with legal_code#exempt_from_rate' do
    it 'should have no rate for placement covering report range' do
      create(:placement_with_rate_exempt, refugee: refugee, moved_in_at: UnitMacros::REPORT_INTERVAL[:from])
      rates = Economy::RatesForRefugee.new(refugee, UnitMacros::REPORT_INTERVAL).as_array
      rate = detect_rate_by_amount(rates, UnitMacros::RATES[:arrival_0_17])

      expect(rate).to eq nil
    end

    it 'should have a reduced number of days rate' do
      create(:placement_with_rate_exempt, refugee: refugee, moved_in_at: UnitMacros::REPORT_INTERVAL[:from].to_date + 1)
      rates = Economy::RatesForRefugee.new(refugee, UnitMacros::REPORT_INTERVAL).as_array
      rate = detect_rate_by_amount(rates, UnitMacros::RATES[:arrival_0_17])

      expect(rate[:days]).to eq 1
    end

    it 'should have a reduced number of days rate' do
      create(
        :placement_with_rate_exempt,
        refugee: refugee,
        moved_in_at: UnitMacros::REPORT_INTERVAL[:from].to_date + 10,
        moved_out_at: UnitMacros::REPORT_INTERVAL[:to].to_date - 10
      )
      rates = Economy::RatesForRefugee.new(refugee, UnitMacros::REPORT_INTERVAL).as_array
      rate = detect_rate_by_amount(rates, UnitMacros::RATES[:arrival_0_17])

      expect(rate[:days]).to eq 20
    end
  end
end
