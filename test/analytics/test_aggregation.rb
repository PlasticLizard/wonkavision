module Rpm
  class AccountSummary
    include Wonkavision::Analytics::Aggregation

    event 'wv.billing_record.sample_added',
          'wv.billing_record.sample_retracted'

    dimension :company_id
    dimension :current_payer_class, :current_payer
    dimension :primary_payer_class, :primary_payer
    dimension :status_category, :status
    dimension :age_category
    dimension :has_credit_balance

    measure :age_in_days
    measure :write_offs, :charges, :payments, :current_balance

    aggregate_by :company_id do
      aggregate_by :status_category
      aggregate_by :status
      aggregate_by :primary_payer_class, :has_credit_balance
      aggregate_by :current_payer_class, :has_credit_balance
    end

  end
end

#wv.billing_record.sample
{
  action => :add,
  #dimension data
  :company_id => "123",
  :current_payer_class => "commercial",
  :current_payer => "payer_xyz",
  :primary_payer_class => "commercial",
  :primary_payer => "payer_abc",
  :status_category => "category 1",
  :status => :"status 1",
  :age_category => "0-30 days",
  :has_credit_balance => true,
  #measure data
  :age_in_days => 21,
  :write_offs => 123.45,
  :charges => 456.78,
  :payments => 12.34,
  :current_balance => 320.99
}
#collection name:
#wv.rpm.account_summary
{
  action => :add,
  dimensions => { :status_category => "category 1"},
  measures => {
    :age_in_days => {
      :count => 1,
      :sum => 123,
      :sum2 => 123,
      :mean => 123,
      ...

    },
    :write_offs => {
      :count => 1,
      :sum => 123,
      ...
    }
  }
}

#wv.rpm.account_summary.samples
{
  dimensions => { :status_category => "category 1"},
  measures => {
    :age_in_days => [12 => 1, 34 => 10, ...]
  }
}


