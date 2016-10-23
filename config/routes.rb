Rails.application.routes.draw do
  
  # bot1 flash anzan v1
  post 'bot1_flashanzan/index'
  
  # bot 2 n2 news
  post 'bot2_n2news/index'
  
  # bot3 n2 news sports
  post 'bot3_n2newssp/index'
  
  # bot4 n2 news geinou
  post 'bot4_n2newsgn/index'
  
  # bot5 n2 news bz
  post 'bot5_n2newsbz/index'
  
  # bot6 n2 news IT
  post 'bot6_n2newsit/index'
  
  # bot  eitango 
  
  # bot  quizPart1 eng
  
  # resque
  mount Resque::Server.new, at: "/resque"
  
  
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
