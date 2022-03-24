import Iter "mo:base/Iter";
import List "mo:base/List";
import Microblog "mo:base/Principal";
import Principal "mo:base/Principal";
import Time "mo:base/Time";
actor {
    public type Message = {
        content : Text;
        time : Time.Time;
        author: Text;
    };
    public type Follow_info = {
        name : ?Text;
        cid : Text;
    };
    public type Microblog = actor {
        follow: shared(Principal) -> async ();
        follows: shared query () -> async [Principal];
        post: shared (Text) -> async ();
        posts: shared query (Int) -> async [Message];
        timeline: shared () -> async [Message];
        set_name: shared (Text) -> async ();
        get_name: shared query () -> async ?Text;
        visit_count: shared () -> async (); 
        get_visit_time: shared query () -> async Int;
        someone_posts: shared (Text) -> async [Message];
        get_follow_infos: shared () -> async [Follow_info];
        update_follow_infos: shared () -> async ();
        reset_follows: shared () -> async ();
        follow_by_text: shared (Text) -> async ();
    };
    stable var follow_infos :  List.List<Follow_info> = List.nil();
    stable var followed : List.List<Principal> = List.nil(); 
    stable var name : Text = "nil";
    stable var visit_time : Int = 0;
    public shared func visit_count() : async (){
        visit_time := visit_time + 1;
    };
    public shared query func get_visit_time() : async Int{
        visit_time
    };
    public shared (msg) func set_name(text : Text) : async () {
        name := text;
    };
    public shared query func get_name() : async Text{
        name
    };

    public shared func get_follow_infos() : async [Follow_info]{      
        List.toArray(follow_infos);
    };

    public shared func update_follow_infos() : async (){
        follow_infos := List.nil();
        for (id in Iter.fromList(followed)) {
            let canister : Microblog = actor(Principal.toText(id));
            let ms = await canister.get_name();
            let info : Follow_info = {name=ms;cid=Principal.toText(id)};
            follow_infos := List.push(info,follow_infos);
        };
    };

    public shared func follow(id : Principal) : async (){
        var unfollowed = true;
        for(p in Iter.fromList(followed)){
            if(p.equal(id)){
                unfollowed = false;
            }
        }
        if(unfollowed){
            followed := List.push(id,followed);
            await update_follow_infos();
        }
    };

    public shared func follow_by_text(cid : Text) : async (){
        let id : Principal = Principal.fromText(cid);
        var unfollowed = true;
        for(p in Iter.fromList(followed)){
            if(p.equal(id)){
                unfollowed = false;
            }
        }
        if(unfollowed){
            followed := List.push(id,followed);
            await update_follow_infos();
        }
    };

    public shared func reset_follows() : async (){
        followed := List.nil();
    };

    public shared query func follows() : async [Principal]{
        List.toArray(followed)
    };

    stable var messages : List.List<Message> = List.nil();
    public shared (msg) func post(text : Text) : async () {
        let message : Message = { content=text; time = Time.now(); author = name};
        messages := List.push(message, messages)
    };
    public shared query func posts(since: Time.Time) : async [Message]{
        var res : List.List<Message> = List.nil();
        for(msg in Iter.fromList(messages)){
            if(msg.time > since){
                res := List.push(msg, res);
            };
        };
        List.toArray(res)
    };

    public shared (msg) func timeline(since: Time.Time) : async [Message] {
        var msgs : List.List<Message> = List.nil();
        for (id in Iter.fromList(followed)) {
            let canister : Microblog = actor(Principal.toText(id));
            let ms = await canister.posts(since);
            for (msg in Iter.fromArray(ms)) {
                msgs := List.push(msg, msgs);
            }
        };
        List.toArray(msgs);
    };

    public shared func someone_posts(cid: Text) : async [Message]{
        let canister : Microblog = actor(cid);
        let ms = await canister.posts(0);
        ms;
    }
};