class V2::AyahsController < ApplicationController
  before_filter :validate_params
  before_filter :get_range

  caches_action :index, cache_path: Proc.new {|a| params_hash}, expires_in: 12.hours

  def index
    @ayahs = Quran::Ayah
      .includes(translations: [:resource])
      .includes(glyphs: {word: [:corpus, :translation, :transliteration, :token]})
      .includes(audio: :reciter)
      .includes(:text_tashkeel)
      .where('translation.resource_id' => params[:content])
      .where('file.recitation_id' => params[:audio], 'file.is_enabled' => true)
      .get_ayahs_by_range(params[:surah_id], @range[0], @range[1])
  end

private

  def validate_params
    params.has_key?(:quran) && valid_surah_id? && contains_range?
  end

  def contains_range?
    ((params.has_key?(:from) && params.has_key?(:to)) || params.has_key?(:range))
  end

  def valid_surah_id?
    is_surah_id_in_range?
  end

  def surah_id_integer?
    params[:surah_id].to_i > 0
  end

  def is_surah_id_in_range?
    if surah_id_integer?
      params[:surah_id].to_i > 0 && params[:surah_id].to_i < 115
    end
  end

  def get_range
    if params.key?(:range)
      @range = params[:range].split('-')
    elsif params.key?(:from) && params.key?(:to)
      @range = [params[:from], params[:to]]
    else
      @range = ['1', '10']
    end

    if (@range.last.to_i - @range.first.to_i) > 50
      return render json: {error: "Range invalid, use a string (maximum 50 ayat per request), e.g. '1-3'"}
    end
  end

  def params_hash
    "v2/#{params[:surah_id]}" + (params[:range] || ("#{params[:from]}-#{params[:to]}")) + "/1/#{params[:audio]}/#{params[:content]}"
  end
end