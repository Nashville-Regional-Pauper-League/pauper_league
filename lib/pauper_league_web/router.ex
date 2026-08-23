defmodule PauperLeagueWeb.Router do
  use PauperLeagueWeb, :router

  import PauperLeagueWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {PauperLeagueWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", PauperLeagueWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/leaderboard", PageController, :board
    get "/leaderboard/:season_id", PageController, :board
    get "/players/:player_id", PageController, :player
    get "/decks/:deck_id", PageController, :deck
    get "/metagame", PageController, :meta
    get "/events", PageController, :events
    get "/events/:event_id", PageController, :event
    get "/rules", PageController, :rules
  end

  # Other scopes may use custom stacks.
  # scope "/api", PauperLeagueWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:pauper_league, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: PauperLeagueWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", PauperLeagueWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{PauperLeagueWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      # live "/users/register", UserRegistrationLive, :new
      live "/users/log_in", UserLoginLive, :new
      # live "/users/reset_password", UserForgotPasswordLive, :new
      # live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/users/log_in", UserSessionController, :create
  end

  scope "/", PauperLeagueWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{PauperLeagueWeb.UserAuth, :ensure_authenticated}] do
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email
    end
  end

  scope "/admin", PauperLeagueWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/", AdminController, :base
    get "/stores", AdminController, :stores

    live_session :admin,
      on_mount: [{PauperLeagueWeb.UserAuth, :ensure_authenticated}] do
      live "/stores/:store_id", AdminLive.Store, :store
      live "/staged/events/:stage_event_id", AdminLive.StagedEvent, :staged_event
    end
  end

  scope "/", PauperLeagueWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{PauperLeagueWeb.UserAuth, :mount_current_user}] do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end
  end
end
