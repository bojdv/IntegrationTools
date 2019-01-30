class SoapController < ApplicationController

  def name
    names = { 'Бойко' => 'Дина', 'Ткаченко' => 'Никита' }
    render json: { 'name': names[params[:surname]] }
  end

  def user_room
    rooms = { 'Дина' => '211', 'Никита' => '777' }
    render json: { 'room': rooms[params[:name]] }
  end

end
