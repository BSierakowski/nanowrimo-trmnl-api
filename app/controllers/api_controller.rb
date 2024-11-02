class ApiController < ApplicationController
  require 'httparty'

  def fetch_data
    # Load email and password from environment variables
    email = ENV['EMAIL']
    password = ENV['PASSWORD']

    # Step 1: Fetch Auth Token
    auth_response = HTTParty.post(
      'https://api.nanowrimo.org/users/sign_in',
      body: { identifier: email, password: password }
    )

    if auth_response.code != 200
      render json: { error: 'Authentication failed' }, status: :unauthorized
      return
    end

    auth_token = auth_response.headers['Authorization']

    # Step 2: Fetch Project Attributes
    projects_response = HTTParty.get(
      'https://api.nanowrimo.org/projects/3642775/project-challenges',
      headers: { 'Authorization' => auth_token }
    )

    if projects_response.code != 200
      render json: { error: 'Failed to fetch projects' }, status: :bad_request
      return
    end

    # Step 3: Fetch Daily Attributes
    daily_response = HTTParty.get(
      'https://api.nanowrimo.org/project-challenges/4003178/daily-aggregates',
      headers: { 'Authorization' => auth_token }
    )

    if daily_response.code != 200
      render json: { error: 'Failed to fetch daily aggregates' }, status: :bad_request
      return
    end

    # Log the attributes to the server log
    Rails.logger.info "Projects Attributes: #{projects_response.body}"
    Rails.logger.info "Daily Attributes: #{daily_response.body}"

    # Send a single JSON payload back from the request
    render json: {
      projects: JSON.parse(projects_response.body),
      daily_aggregates: JSON.parse(daily_response.body)
    }
  end
end
