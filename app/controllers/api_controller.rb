class ApiController < ApplicationController
  require 'httparty'

  def fetch_data
    # Load email and password from environment variables
    email = ENV['EMAIL']
    password = ENV['PASSWORD']

    # Fetch the IDs from URL parameters
    project_id = params[:project_id]
    project_challenge_id = params[:project_challenge_id]

    # Step 1: Fetch Auth Token
    auth_response = HTTParty.post(
      'https://api.nanowrimo.org/users/sign_in',
      body: { identifier: email, password: password }
    )

    if auth_response.code != 200
      Rails.logger.error "Authentication failed: #{auth_response.body}"
      render json: { error: 'Authentication failed' }, status: :unauthorized
      return
    end

    parsed_body = JSON.parse(auth_response.body)
    auth_token = parsed_body["auth_token"]

    # Ensure the auth token is present
    unless auth_token
      Rails.logger.error 'Auth token not found in the response headers.'
      render json: { error: 'Auth token not found' }, status: :unauthorized
      return
    end

    # Step 2: Fetch Project Attributes
    projects_url = "https://api.nanowrimo.org/projects/#{project_id}/project-challenges"
    projects_response = HTTParty.get(
      projects_url,
      headers: { 'Authorization' => auth_token }
    )

    if projects_response.code != 200
      Rails.logger.error "Failed to fetch projects: #{projects_response.body}"
      render json: { error: 'Failed to fetch projects' }, status: :bad_request
      return
    end

    # Step 3: Fetch Daily Attributes
    daily_url = "https://api.nanowrimo.org/project-challenges/#{project_challenge_id}/daily-aggregates"
    daily_response = HTTParty.get(
      daily_url,
      headers: { 'Authorization' => auth_token }
    )

    if daily_response.code != 200
      Rails.logger.error "Failed to fetch daily aggregates: #{daily_response.body}"
      render json: { error: 'Failed to fetch daily aggregates' }, status: :bad_request
      return
    end

    # Log the attributes to the server log
    Rails.logger.info "Projects Attributes: #{projects_response.body}"
    Rails.logger.info "Daily Attributes: #{daily_response.body}"

    parsed_projects_data = JSON.parse(projects_response.body)
    parsed_daily_data = JSON.parse(daily_response.body)

    project_attributes = parsed_projects_data["data"].first["attributes"]
    daily_attributes = parsed_daily_data["data"].first["attributes"]

    days_remaining = (Date.parse(project_attributes["ends-at"]) - Date.today).to_i
    words_remaining = project_attributes["goal"] - project_attributes["current-count"]

    words_per_day = words_remaining / days_remaining

    return_attributes = {
      starts_at: project_attributes["starts-at"],
      ends_at: project_attributes["ends-at"],
      goal: project_attributes["goal"],
      current_count: project_attributes["current-count"],
      streak: project_attributes["streak"],
      days_remaining: days_remaining,
      words_remaining: words_remaining,
      words_per_day: words_per_day
    }


    # Send a single JSON payload back from the request
    render json: {
      project_attributes: return_attributes,
      daily_aggregates: daily_attributes
    }
  end
end
