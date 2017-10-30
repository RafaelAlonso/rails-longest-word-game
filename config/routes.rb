Rails.application.routes.draw do
  root to: 'pages#game'

  get 'score', to: 'pages#score'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
