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
  
  # bot7 n2 matome
  post 'bot7_n2matome/index'
  
  # bot8 n2 asiato
  post 'bot8_n2asiato/index'
  
  # bot9 n2 ネタ画像探し
  post 'bot9_n2randimg/index'
  
  # bot10 n2 ネタ画像探し5 
  post 'bot10_n2imgsearch/index'
  
  # bot11 n2 ネタ画像検索 group対応
  post 'bot11_n2imgmsgsearch/index'
  
  # bot12 n2 ネタ画像Sbot group対応
  post 'bot12_n2imgmsgsearchsimple/index'
  
  # bot13 n2 タッチスリー
  post 'bot13_n2touch3/index'
  
  # bot15 N2リアFAQ
  post 'bot15_n2realtimefaq/index'
  get 'bot15_n2realtimefaq/show' # PC/SPブラウザ向け閲覧ページ
  post 'bot15_n2realtimefaq/fetch' # ajax定期フェッチ
  
  # bot19 日本地図クイズ ３択
  post 'bot19_n2jpquiz3/index'
  # bot20 日本地図クイズ ３択 ひらがな版
  post 'bot20_n2jpquiz3hira/index'
  
  # bot21 宿予約
  post 'bot21_n2rsvinn/index' # bot
  get 'bot21_n2rsvinn/imagemap/cal/:year/:month/:timestamp/:size' => 'bot21_n2rsvinn#cal_img' # bot 日付選択カレンダー画像を返す 1040x1040
  get 'bot21_n2rsvinn/mgr' # 管理画面トップ
  
  # bot22 日本地図クイズ幼児ひらがな版 ４択
  post 'bot22_n2jpquiz3hirakai/index'

  # bot23 N2 都道府県形クイズ4択 幼児向け  
  post 'bot23_n2jpshapequizyouji/index'

  # bot24 N2 校正ちゃん
  post 'bot24_n2kouseichan/index'
  
  # bot25 N2せっかち君
  post 'bot25_n2sekkatikun/index'
  
  # bot26 N2ぼかっしゅ
  post 'bot26_n2bokashu/index'
  
  # bot27 N2誤爆防止ボット
  post 'bot27_n2gobakuboushi/index'
  
  # bot  eitango 
  
  # bot  quizPart1 eng
  
  
  # bot100 LINE botハッカソン
  post 'bot100/index'
  get 'bot100/show' # PC/SPブラウザ向け閲覧ページ
  post 'bot100/fetch' # ajax定期フェッチ

  # webhook git and pull
  get 'pullgit/index'
  post 'pullgit/index'

  # google calendar api oauth callback
  get 'google_cal/callback' # dummy
  get 'oauth2callback' => 'google_cal#callback' # 実際

  # google calendar event watch webhook url
  post 'google_cal/webhook' # dummy
  
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
