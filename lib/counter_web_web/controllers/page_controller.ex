defmodule CounterWebWeb.PageController do
  use CounterWebWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
