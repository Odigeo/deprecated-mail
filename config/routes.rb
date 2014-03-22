Mail::Application.routes.draw do

  scope "v1" do
  	
    resources :mails, only: [:create] do
      post 'send', on: :collection, to: "mails#send_sync"
    end

  end

end
