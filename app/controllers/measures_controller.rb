class MeasuresController < ApplicationController

  layout :select_layout
  before_filter :authenticate_user!
  before_filter :validate_authorization!

  add_breadcrumb 'measures', ""

  rescue_from Mongoid::Errors::Validations do
    render :template => "measures/edit"
  end

  def index
    @measure = Measure.new
    @measures = current_user.measures
    @all_published = Measure.published
  end

  def show
    @measure = Measure.find(params[:id])
  end

  def show_nqf
    @measure = Measure.find(params[:id])
    @contents = File.read(File.expand_path(File.join('.','tmp','measures','html',"#{@measure.id}.html")))
  end

  def publish
    @measure = Measure.find(params[:id])
    @measure.publish

    @show_published=true
    @measures = current_user.measures
    @all_published = Measure.published

    flash[:notice] = "Published #{@measure.title}."
    render :index
  end

  def published
    @measures = Measure.published.map(&:latest_version)
  end

  def new
    @measure = Measure.new
  end

  def edit
    @editing=true
    @measure = Measure.find(params[:id])
  end

  def create
    # Value sets
    value_set_file = params[:measure][:value_sets]
    value_set_path = value_set_file.tempfile.path
    value_set_format = HQMF::ValueSet::Parser.get_format(value_set_file.original_filename)

    # Load the actual measure
    hqmf_path = params[:measure][:hqmf].tempfile.path
    html_path = params[:measure][:html].tempfile.path

    measure = Measures::Loader.load(hqmf_path, value_set_path, current_user, value_set_format, html_path)

    redirect_to edit_measure_url(measure)
  end

  def upsert_criteria
    @measure = Measure.find(params[:id])
    criteria = {"id" => params[:criteria_id]  || BSON::ObjectId.new.to_s, "type" => params['type']}
    ["title", "code_list_id", "description", "qds_data_type", 'negation_code_list_id'].each { |f| criteria[f] = params[f] if !params[f].blank?}


    # Do that HQMF Processing
    criteria = {'id' => criteria['id'] }.merge JSON.parse(HQMF::DataCriteria.create_from_category(criteria['id'], criteria['title'], criteria['description'], criteria['code_list_id'], params['category'], params['subcategory'], !criteria['negation'].blank?, criteria['negation_code_list_id']).to_json.to_json).flatten[1]
    
    ["display_name"].each { |f| criteria[f] = params[f] if !params[f].nil?}
    ["property", "children_criteria"].each { |f| criteria[f] = params[f] if !params[f].blank?}

    criteria['value'] = if params['value'] then JSON.parse(params['value']) else nil end
    criteria['temporal_references'] = if params['temporal_references'] then JSON.parse(params['temporal_references']) else nil end
    criteria['subset_operators'] = if params['subset_operators'] then JSON.parse(params['subset_operators']) else nil end
    criteria['field_values'] = if params['field_values'] then JSON.parse(params['field_values']) else nil end

    @measure.upsert_data_criteria(criteria, params['source'])
    render :json => @measure.data_criteria[criteria['id']] if @measure.save
  end

  def update
    @measure = Measure.find(params[:id])
    @measure.update_attributes!(params[:measure])

    redirect_to @measure, notice: 'Measure was successfully updated.'
  end

  def destroy
    @measure = Measure.find(params[:id])
    @measure.destroy

    redirect_to measures_url
  end

  def select_layout
    case @_action_name
    when 'show_nqf'
      "empty"
    else
      "measure_page"
    end
  end

  def validate_authorization!
    authorize! :manage, Measure
  end

  def definition
    measure = Measure.find(params[:id])
    population_index = params[:population].to_i if params[:population]
    population = measure.parameter_json(population_index)
    render :json => population
  end

  def population_criteria_definition
    measure = Measure.find(params[:id])
    population = measure.population_criteria_json(measure.population_criteria[params[:key]])
    render :json => population
  end

  def export
    measure = Measure.find(params[:id])

    file = Tempfile.new(["#{measure.id}-#{Time.now.to_i}", ".zip"])
    Measures::Exporter.export(file, [measure])

    send_file file.path, :type => 'application/zip', :disposition => 'attachment', :filename => "measures.zip"
  end

  def export_all
    measures = Measure.by_user(current_user)

    file = Tempfile.new(["#{current_user.id}-#{Time.now.to_i}", ".zip"])
    Measures::Exporter.export(file, measures)

    send_file file.path, :type => 'application/zip', :disposition => 'attachment', :filename => "measures.zip"
  end

  def generate_patients
    measure = Measure.find(params[:id])
    measure.records.destroy_all

    begin
      generator = HQMF::Generator.new(measure.as_hqmf_model, measure.value_sets)
      measure.records = generator.generate_patients
      measure.save
    rescue
    end

    redirect_to :test_measure
  end

  def download_patients
    measure = Measure.find(params[:id])
    zip = TPG::Exporter.zip(measure.records, "c32")

    send_file zip.path, :type => 'application/zip', :disposition => 'attachment', :filename => "patients.zip"
  end

  def debug
    @measure = Measure.find(params[:id])
    @patient = Record.find(params[:record_id])
    @population = (params[:population] || 0).to_i

    respond_to do |wants|
      wants.html do
        @js = Measures::Exporter.execution_logic(@measure, @population)
      end
      wants.js do
        @measure_js = Measures::Exporter.execution_logic(@measure, @population)
        render :content_type => "application/javascript"
      end
    end
  end
  def debug_libraries
    respond_to do |wants|
      wants.js do
        @libraries = Measures::Exporter.library_functions
        render :content_type => "application/javascript"
      end
    end
  end


  def test
    @population = params[:population] || 0
    @measure = Measure.find(params[:id])
    @patient_names = @measure.records.entries.collect {|r| [
      "#{r[:first]} #{r[:last]}",
      r[:_id].to_s,
      {'description' => r['description'], 'category' => r['description_category']},
      {'start' => r['measure_period_start'], 'end' => r['measure_period_end']}
    ]}

    # we need to manipulate params[:patients] but it's immutable?
    if params[:patients]
      # full of {"4fa98074431a5fb25f000132"=>1} etc
      @patients_posted = params[:patients].collect {|p| { p[0] => p[1].to_i } }
      # reject patients that were not posted (checkbox not checked)
      @patients_posted.reject! {|p| p.flatten[1] == 0}
      # now full of ["4fa98074431a5fb25f000132"]
      @patients_posted = @patients_posted.collect {|p| p.keys}.flatten
    end
  end

  ####
  ## POPULATIONS
  ####
  def update_population
    @measure = Measure.find(params[:id])
    index = params['index'].to_i
    title = params['title']
    @measure.populations[index]['title'] = title
    @measure.save!
    render partial: 'populations', locals: {measure: @measure}
  end

  def delete_population
    @measure = Measure.find(params[:id])
    index = params['index'].to_i
    @measure.populations.delete_at(index)
    @measure.save!
    render partial: 'populations', locals: {measure: @measure}
  end
  def add_population
    @measure = Measure.find(params[:id])
    population = {}
    population['title']= params['title']

    ['IPP','DENOM','NUMER','EXCL','DENEXCEP'].each do |key|
      population[key]= params[key] unless params[key].empty?
    end

    if (population['NUMER'] and population['IPP'])
      @measure.populations << population
      @measure.save!
    else
      raise "numerator and initial population must be provided"
    end


    render partial: 'populations', locals: {measure: @measure}
  end
  def update_population_criteria
    @measure = Measure.find(params[:id])
    @measure.create_hqmf_preconditions(params['data'])
    #@measure.save!
    render :json => {
      'population_criteria' => {{
        "IPP" => "population",
        "DENOM" => "denominator",
        "NUMER" => "numerator",
        "EXCL" => "exclusions",
        "DENEXCEP" => "exceptions"
      }[params['data']['type']] => @measure.population_criteria_json(@measure.population_criteria[params['data']['type']])},
      'data_criteria' => @measure.data_criteria
    }
  end

  def name_precondition
    @measure = Measure.find(params[:id])
    @measure.name_precondition(params[:precondition_id], params[:name])
    render :json => @measure.save!
  end

  def save_data_criteria
    @measure = Measure.find(params[:id])
    @measure.data_criteria[params[:criteria_id]]['saved'] = true
    render :json => @measure.save!
  end

  def patient_builder
    @measure = Measure.find(params[:id])
    @record = @measure.records.select{|r| r['_id'].to_s == params[:patient_id]}[0] || {}
  end

  def make_patient
    @measure = Measure.find(params[:id])
    values = Hash[@measure.value_sets.map{|v| [v['oid'], v]}]
    params['birthdate'] = params['birthdate'].to_i / 1000
    patient = HQMF::Generator.create_base_patient(params.select{|k| ['first', 'last', 'gender', 'expired', 'birthdate'].include?k })
    patient['source_data_criteria'] = JSON.parse(params['data_criteria'])
    patient['description'] = params['description']
    patient['description_category'] = params['description_category']
    patient['measure_period_start'] = params['measure_period_start'].to_i
    patient['measure_period_end'] = params['measure_period_end'].to_i
    JSON.parse(params['data_criteria']).each {|v|
      data_criteria = HQMF::DataCriteria.from_json(v['id'], @measure.source_data_criteria[v['id']])
      data_criteria.modify_patient(patient, HQMF::Range.from_json({
        'low' => {'value' => Time.at(v['start_date'] / 1000).strftime('%Y%m%d')},
        'high' => {'value' => Time.at(v['end_date'] / 1000).strftime('%Y%m%d')}
      }), HQMF::Range.from_json('low' => {'value' => v['value'], 'unit' => v['value_unit']}), values[data_criteria.code_list_id])
    }
    patient['source_data_criteria'].push({'id' => 'MeasurePeriod', 'start_date' => params['measure_period_start'].to_i, 'end_date' => params['measure_period_end'].to_i})
    if params['record_id'].blank?
      @measure.records.push(patient)
    else
      @measure.records = @measure.records.map{|r| if r['_id'].to_s == params['record_id'] then patient else r end }
    end
    render :json => @measure.save!
  end

  def delete_patient
    @measure = Measure.find(params[:id])
    @measure.records = @measure.records.reject{|v| v['_id'].to_s == params['victim']}
    render :json => @measure.save!
  end
end
