port module Setup.Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (class, value, type_, id, style, src, title, href, target)
import Html.Events exposing (on, keyCode, onClick, onInput, onSubmit)
import Json.Decode as Json
import Task
import Dom
import Mobster exposing (MoblistOperation)
import Json.Decode as Decode
import Keyboard.Combo
import Random
import Array


onEnter : Msg -> Attribute Msg
onEnter msg =
    let
        isEnter code =
            if code == 13 then
                Json.succeed msg
            else
                Json.fail "not the right keycode"
    in
        on "keydown" (keyCode |> Json.andThen isEnter)


type Msg
    = StartTimer
    | UpdateMoblist MoblistOperation
    | UpdateMobsterInput String
    | AddMobster
    | ClickAddMobster
    | DomFocusResult (Result Dom.Error ())
    | ChangeTimerDuration String
    | SelectDurationInput
    | OpenConfigure
    | NewTip Int
    | Quit
    | ComboMsg Keyboard.Combo.Msg


keyboardCombos : List (Keyboard.Combo.KeyCombo Msg)
keyboardCombos =
    [ Keyboard.Combo.combo2 ( Keyboard.Combo.control, Keyboard.Combo.enter ) StartTimer
    , Keyboard.Combo.combo2 ( Keyboard.Combo.command, Keyboard.Combo.enter ) StartTimer
    ]


type ScreenState
    = Configure
    | Continue


type alias Model =
    { timerDuration : Int
    , screenState : ScreenState
    , mobsterList : Mobster.MobsterData
    , newMobster : String
    , combos : Keyboard.Combo.Model Msg
    , tip : Tip
    }


emptyTip : Tip
emptyTip =
    { url = "", title = "", body = text "" }


changeTip : Cmd Msg
changeTip =
    Random.generate NewTip (Random.int 0 ((List.length tips) - 1))


initialModel : Model
initialModel =
    { timerDuration = 5
    , screenState = Configure
    , mobsterList = Mobster.empty
    , newMobster = ""
    , combos = Keyboard.Combo.init ComboMsg keyboardCombos
    , tip = emptyTip
    }


type alias TimerConfiguration =
    { minutes : Int, driver : String, navigator : String }


flags : Model -> TimerConfiguration
flags model =
    let
        driverNavigator =
            Mobster.nextDriverNavigator model.mobsterList
    in
        { minutes = model.timerDuration
        , driver = driverNavigator.driver.name
        , navigator = driverNavigator.navigator.name
        }


port startTimer : TimerConfiguration -> Cmd msg


port saveSetup : Mobster.MobsterData -> Cmd msg


port quit : () -> Cmd msg


port selectDuration : String -> Cmd msg


timerDurationInputView : Int -> Html Msg
timerDurationInputView duration =
    div [ class "text-primary h1" ]
        [ input
            [ id "timer-duration"
            , onClick SelectDurationInput
            , onInput ChangeTimerDuration
            , type_ "number"
            , Html.Attributes.min "1"
            , Html.Attributes.max "15"
            , value (toString duration)
            , class "right-buffer"
            , style [ ( "font-size", "60px" ) ]
            ]
            []
        , text "Minutes"
        ]


quitButton : Html Msg
quitButton =
    button [ onClick Quit, class "btn btn-primary btn-md btn-block" ] [ text "Quit" ]


titleTextView : Html msg
titleTextView =
    h1 [ class "text-info text-center", id "mobster-title", style [ ( "font-size", "62px" ) ] ] [ text "Mobster" ]


invisibleTrigger : Html msg
invisibleTrigger =
    img [ src "./assets/invisible.png", class "invisible-trigger pull-left", style [ ( "max-width", "35px" ) ] ] []


configureView : Model -> Html Msg
configureView model =
    div [ class "container-fluid" ]
        [ div [ class "row" ]
            [ invisibleTrigger
            , titleTextView
            ]
        , button [ onClick StartTimer, class "btn btn-info btn-lg btn-block top-buffer", title "Ctrl+Enter or ⌘+Enter", style [ ( "font-size", "30px" ), ( "padding", "20px" ) ] ] [ text "Start Mobbing" ]
        , div [ class "row" ]
            [ div [ class "col-md-6" ] [ timerDurationInputView model.timerDuration ]
            , div [ class "col-md-6" ] [ mobstersView model.newMobster (Mobster.mobsters model.mobsterList) ]
            ]
        , div [ class "row top-buffer" ] [ quitButton ]
        ]


continueView : Model -> Html Msg
continueView model =
    div [ class "container-fluid" ]
        [ div [ class "row" ]
            [ invisibleTrigger
            , titleTextView
            ]
        , div [ class "row", style [ ( "padding-bottom", "20px" ) ] ]
            [ button [ onClick StartTimer, class "btn btn-info btn-lg btn-block top-buffer", title "Ctrl+Enter or ⌘+Enter", style [ ( "font-size", "30px" ), ( "padding", "20px" ) ] ] [ text "Continue" ]
            ]
        , nextDriverNavigatorView model
        , tipView model.tip
        , div [ class "row top-buffer", style [ ( "padding-bottom", "20px" ) ] ] [ button [ onClick OpenConfigure, class "btn btn-primary btn-md btn-block" ] [ text "Configure" ] ]
        , div [ class "row top-buffer" ] [ quitButton ]
        ]


type alias Tip =
    { url : String
    , body : Html Msg
    , title : String
    }


tips : List Tip
tips =
    [ { url = "http://llewellynfalco.blogspot.com/2014/06/llewellyns-strong-style-pairing.html"
      , body =
            blockquote []
                [ p [] [ text "For an idea to go from your head into the computer it MUST go through someone else's hands" ]
                , small [] [ text "Llewellyn Falco" ]
                ]
      , title = "Driver/Navigator Pattern"
      }
    , { url = "http://llewellynfalco.blogspot.com/2014/06/llewellyns-strong-style-pairing.html"
      , body =
            blockquote []
                [ p [ style [ ( "font-size", "20px" ) ] ] [ text "When you are the driver trust that your navigator knows what they are telling you. If you don't understand what they are telling you ask questions, but if you don't understand why they are telling you something don't worry about it until you've finished the method or section of code. The right time to discuss and challenge design decisions is after the solution is out of the navigator's head or when the navigator is confused and unable to navigate." ]
                , small [] [ text "Llewellyn Falco" ]
                ]
      , title =
            "Trust your navigator"
      }
    , { url = "http://llewellynfalco.blogspot.com/2014/06/llewellyns-strong-style-pairing.html"
      , title =
            "Driving With An Idea"
      , body =
            blockquote []
                [ p [] [ text "What if I have an idea I want to implement? Great! Switch places and become the navigator." ]
                , small [] [ text "Llewellyn Falco" ]
                ]
      }
    ]


tipView : Tip -> Html Msg
tipView tip =
    div [ class "jumbotron tip", style [ ( "margin", "0px" ), ( "padding", "25px" ) ] ]
        [ div [ class "row" ]
            [ h2 [ class "text-success pull-left", style [ ( "margin", "0px" ), ( "padding-bottom", "10px" ) ] ]
                [ text tip.title ]
            , a [ target "_blank", class "btn btn-sm btn-primary pull-right", href tip.url ] [ text "Learn More" ]
            ]
        , div [ class "row", style [ ( "font-size", "20px" ) ] ] [ tip.body ]
        ]


nextDriverNavigatorView : Model -> Html Msg
nextDriverNavigatorView model =
    let
        driverNavigator =
            Mobster.nextDriverNavigator model.mobsterList
    in
        div [ class "row h1" ]
            [ div [ class "text-muted col-md-3" ] [ text "Next:" ]
            , driverView driverNavigator.driver
            , navigatorView driverNavigator.navigator
            , button [ class "btn btn-small btn-default", onClick (UpdateMoblist Mobster.SkipTurn) ] [ text "Skip Turn" ]
            ]


driverView : Mobster.Mobster -> Html Msg
driverView mobster =
    div [ class "col-md-4 text-default" ]
        [ iconView "./assets/driver-icon.png" 40
        , span [ class "right-buffer" ] [ text mobster.name ]
        , button [ onClick (UpdateMoblist (Mobster.Remove mobster.index)), class "btn btn-small btn-default" ] [ text "Not here" ]
        ]


navigatorView : Mobster.Mobster -> Html Msg
navigatorView mobster =
    div [ class "col-md-4 text-default" ]
        [ iconView "./assets/navigator-icon.png" 40
        , span [ class "right-buffer" ] [ text mobster.name ]
        , button [ onClick (UpdateMoblist (Mobster.Remove mobster.index)), class "btn btn-small btn-default" ] [ text "Not here" ]
        ]


iconView : String -> Int -> Html msg
iconView iconUrl maxWidth =
    img [ style [ ( "max-width", (toString maxWidth) ++ "px" ), ( "margin-right", "8px" ) ], src iconUrl ] []


nextView : String -> String -> Html msg
nextView thing name =
    span []
        [ span [ class "text-muted" ] [ text ("Next " ++ thing ++ ": ") ]
        , span [ class "text-info" ] [ text name ]
        ]


addMobsterInputView : String -> Html Msg
addMobsterInputView newMobster =
    div [ class "row top-buffer" ]
        [ div [ class "input-group" ]
            [ input [ id "add-mobster", Html.Attributes.placeholder "Jane Doe", type_ "text", class "form-control", value newMobster, onInput UpdateMobsterInput, onEnter AddMobster, style [ ( "font-size", "30px" ) ] ] []
            , span [ class "input-group-btn", type_ "button" ] [ button [ class "btn btn-primary", onClick ClickAddMobster ] [ text "Add Mobster" ] ]
            ]
        ]


mobstersView : String -> List Mobster.MobsterWithRole -> Html Msg
mobstersView newMobster mobsters =
    div [ style [ ( "padding-bottom", "35px" ) ] ]
        [ addMobsterInputView newMobster
        , table [ class "table h3" ] (List.map mobsterView mobsters)
        ]


mobsterView : Mobster.MobsterWithRole -> Html Msg
mobsterView mobster =
    tr []
        [ td [] [ roleView mobster.role ]
        , td [ style [ ( "width", "200px" ), ( "min-width", "200px" ), ( "text-align", "right" ), ( "padding-right", "10px" ) ] ] [ text mobster.name ]
        , td [] [ reorderButtonView mobster.index ]
        ]


roleView : Maybe Mobster.Role -> Html Msg
roleView role =
    case role of
        Just (Mobster.Driver) ->
            iconView "./assets/driver-icon.png" 20

        Just (Mobster.Navigator) ->
            iconView "./assets/navigator-icon.png" 20

        Nothing ->
            span [] []


reorderButtonView : Int -> Html Msg
reorderButtonView mobsterIndex =
    div [ class "btn-group btn-group-xs" ]
        [ button [ class "btn btn-small btn-default", onClick (UpdateMoblist (Mobster.MoveUp mobsterIndex)) ] [ text "↑" ]
        , button [ class "btn btn-small btn-default", onClick (UpdateMoblist (Mobster.MoveDown mobsterIndex)) ] [ text "↓" ]
        , button [ class "btn btn-small btn-danger", onClick (UpdateMoblist (Mobster.Remove mobsterIndex)) ] [ text "x" ]
        , button [ class "btn btn-small btn-default", onClick (UpdateMoblist (Mobster.SetNextDriver mobsterIndex)) ] [ text "Drive" ]
        ]


view : Model -> Html Msg
view model =
    case model.screenState of
        Configure ->
            configureView model

        Continue ->
            continueView model


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        StartTimer ->
            let
                rotatedMobsterData =
                    Mobster.rotate model.mobsterList
            in
                { model
                    | screenState = Continue
                    , mobsterList = rotatedMobsterData
                }
                    ! [ (startTimer (flags model)), changeTip ]

        ChangeTimerDuration durationAsString ->
            let
                rawDuration =
                    Result.withDefault 5 (String.toInt durationAsString)

                duration =
                    if rawDuration > 15 then
                        15
                    else if rawDuration < 1 then
                        1
                    else
                        rawDuration
            in
                { model | timerDuration = duration } ! []

        SelectDurationInput ->
            model ! [ selectDuration "timer-duration" ]

        OpenConfigure ->
            { model | screenState = Configure } ! []

        AddMobster ->
            if model.newMobster == "" then
                model ! []
            else
                let
                    updatedModel =
                        (addMobster model.newMobster model)
                in
                    updatedModel ! [ saveSetup updatedModel.mobsterList ]

        ClickAddMobster ->
            if model.newMobster == "" then
                model ! []
            else
                let
                    command =
                        Task.attempt DomFocusResult (Dom.focus "add-mobster")

                    updatedModel =
                        (addMobster model.newMobster model)
                in
                    updatedModel ! [ command, saveSetup updatedModel.mobsterList ]

        DomFocusResult _ ->
            model ! []

        UpdateMoblist operation ->
            let
                updatedMobsterData =
                    Mobster.updateMoblist operation model.mobsterList
            in
                { model
                    | mobsterList = updatedMobsterData
                }
                    ! [ saveSetup updatedMobsterData ]

        UpdateMobsterInput text ->
            { model | newMobster = text } ! []

        Quit ->
            model ! [ quit () ]

        ComboMsg msg ->
            let
                updatedCombos =
                    Keyboard.Combo.update msg model.combos
            in
                { model | combos = updatedCombos } ! []

        NewTip tipIndex ->
            let
                maybeTip =
                    Array.get tipIndex (Array.fromList tips)

                tip =
                    Maybe.withDefault emptyTip maybeTip
            in
                { model | tip = tip } ! []


addMobster : String -> Model -> Model
addMobster newMobster model =
    let
        updatedMobsterData =
            Mobster.add
                model.newMobster
                model.mobsterList
    in
        { model | newMobster = "", mobsterList = updatedMobsterData }


init : Decode.Value -> ( Model, Cmd Msg )
init flags =
    let
        decodedMobsterData =
            Mobster.decode flags
    in
        case decodedMobsterData of
            Ok mobsterData ->
                { initialModel | mobsterList = mobsterData } ! []

            Err errorString ->
                initialModel ! []


subscriptions : Model -> Sub Msg
subscriptions model =
    Keyboard.Combo.subscriptions model.combos


main : Program Decode.Value Model Msg
main =
    Html.programWithFlags
        { init = init
        , subscriptions = subscriptions
        , update = update
        , view = view
        }
