Rails.application.routes.draw do
  root 'top#index'
  post 'top/create' => 'top#create'
end
