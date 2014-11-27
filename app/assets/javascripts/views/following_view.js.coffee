class @MainAndMe.Views.FollowingView extends MainAndMe.Views.BaseView
  template: JST["following_view"]
  events:
    "click #following_stores_btn": "showFollowingStores"
    "click #following_communities_btn": "showFollowingCommunities"
    "click #following_users_btn": "showFollowingUsers"

  initialize:(options)->
    @user_id = options.user_id
    @render()

  render:=>
    @$el.html(@template())
    @showFollowingUsers()

  showFollowingStores:=>
    @mark_selected_button("#following_stores_btn")
    collection = new MainAndMe.Collections.FollowingStores(user_id: @user_id)
    @$("#following_content").html(new MainAndMe.Views.StoresGridView(collection: collection, columns: 3).el)

  showFollowingUsers:=>
    @mark_selected_button("#following_users_btn")
    followings = new MainAndMe.Collections.FollowingUsers(user_id: @user_id)
    @$("#following_content").html(new MainAndMe.Views.UserFollowListView(collection: followings).el)

  showFollowingCommunities:=>
    @mark_selected_button("#following_communities_btn")
    collection = new MainAndMe.Collections.FollowingCommunities(user_id: @user_id)
    @$("#following_content").html(new MainAndMe.Views.CommunitiesGridView(collection: collection, columns: 3).el)

  mark_selected_button: (button_selector)=>
    @$("#{button}").removeClass("selected") for button in ['#following_stores_btn', '#following_communities_btn', '#following_users_btn']
    @$("#{button_selector}").addClass("selected")

