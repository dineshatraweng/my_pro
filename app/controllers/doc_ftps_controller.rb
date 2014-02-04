class DocFtpsController < ApplicationController
  before_filter :require_admin
  before_filter :init_controller

  # GET /doc_ftps
  # GET /doc_ftps.xml
  def index
    @doc_ftps = DocFtp.order("created_at DESC").all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @doc_ftps }
    end
  end

  # GET /doc_ftps/1
  # GET /doc_ftps/1.xml
  def show
    if @doc_ftp.blank?
      redirect_to doc_ftps_path
    else
      respond_to do |format|
        format.html # show.html.erb
        format.xml  { render :xml => @doc_ftp }
      end
    end
  end

  # GET /doc_ftps/new
  # GET /doc_ftps/new.xml
  def new
    @doc_ftp = DocFtp.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @doc_ftp }
    end
  end

  # GET /doc_ftps/1/edit
  def edit
  end

  # POST /doc_ftps
  # POST /doc_ftps.xml
  def create
    @doc_ftp = DocFtp.new(params[:doc_ftp])

    respond_to do |format|
      if @doc_ftp.save
        format.html { redirect_to(doc_ftps_url, :notice => 'Doc ftp was successfully created.') }
        format.xml  { render :xml => @doc_ftp, :status => :created, :location => @doc_ftp }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @doc_ftp.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /doc_ftps/1
  # PUT /doc_ftps/1.xml
  def update

    respond_to do |format|
      if @doc_ftp.update_attributes(params[:doc_ftp])
        format.html { redirect_to(doc_ftps_url, :notice => 'Doc ftp was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @doc_ftp.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /doc_ftps/1
  # DELETE /doc_ftps/1.xml
  def destroy
    @doc_ftp.destroy

    respond_to do |format|
      format.html { redirect_to(doc_ftps_url) }
      format.xml  { head :ok }
    end
  end

  private
  def init_controller
    case action_name.to_sym
      when :show, :edit,:update, :destroy
        begin
          @doc_ftp = DocFtp.find(params[:id])
        rescue
          redirect_to doc_ftps_path
        end
    end
  end

end
