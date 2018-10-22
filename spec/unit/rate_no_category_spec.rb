# Förväntad schablon för TUT 0-17
RSpec.describe 'Rates' do
  let(:refugee) { create(:refugee) }

  before(:each) do
    refugee.reload
    create_rate_categories_with_rates
  end

  describe 'refugee without properties' do
    it 'should not belong to any rate category' do
      rates = Economy::Rates.for_all_rate_categories(refugee, UnitMacros::REPORT_RANGE)
      expect(rates.size).to eq 0
    end
  end
end
