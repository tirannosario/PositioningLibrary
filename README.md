<div align="center">
    <h1>PositioningLibrary</h1>
    <img src="./pic/icon.png" width="74">
</div>

>La libreria permette allo sviluppatore di accedere alla posizione e all'orientamento del device in uno spazio indoor, attraverso poche righe di codice. La libreria usa delle tecniche di Indoor Positioning basate sull'Augmented Reality, in particolare concentrate sul riconoscimento di **Marker** grafici nello spazio circostante.
---
La libreria fornisce aggiornamenti di posizione attraverso un'istanza della classe `LocationProvider`, a cui vengono forniti una serie di oggetti definiti dall'utilizzatore:
- `Building`: identifica una struttura
- `Floor`: identifica un singolo piano di una struttura (*Building*)
- `Marker`: identifica un marker, ha una *Location* che lo localizza in un *Floor*
- `Location`: identifica una **pose** (posizione e orientamento) rispetto all'origine degli assi del *Floor* di appartenenza
---
## :pushpin: Posizionamento dei Marker
I Markers andranno posizionati nel piano da tracciare, e successivamente andranno definite le relative pose. 
- La **pose** di un Marker è definita da:
    -  **x,y** a partire dall'origine, espresse in metri
    - **heading** (orientamento) rispetto all'origine, espresso in radianti
    <p align = "center">
        <img src="./pic/floor_example.svg">
    </p>
    <p align = "center">
    Esempio di Floor (in questo caso una piccola stanza) con i relativi Markers
    </p>
- :large_orange_diamond: M1 = <x:1.95, y:0>, heading: 0
- :large_orange_diamond: M2 = <x:0.33, y:0.88>, heading: -0.785
- :large_orange_diamond: M3 = <x:3.82, y:1.87>, heading: 3.14
- :large_orange_diamond: M4 = <x:5.10, y:0.85>, heading: 1.57
---
## :hammer: Uso
1. Per ricevere gli aggiornamenti di posizione è necessario rendere la propria classe aderente al protocollo `LocationObserver`, implementandone i relativi metodi.
Una classe che aderisce a `LocationObserver` riceve aggiornamenti per quanto riguarda il cambio di posizione, attraverso gli oggetti:
    - `ApproxLocation`, ovvero coordinate, orientamento, raggio e angolo di approssimazione (tramite `onLocationUpdate`)
    - `Floor` (tramite `onFloorChanged`)
    - `Building` (tramite `onBuildingChanged`)
2. È necessario definire i dati che verranno usati dalla libreria per il calcolo della posizione. Sono rese possibili due modalità.
    - __Creazione Dinamica__
        - L'utente definisce dinamicamente i dati, definendo i vari Buildings, Floors e ovviamente Markers. Ogni `Marker` avrà un riferimento ad una immagine che dovrà essere inserita negli **Assets** del progetto. Inoltre per ogni `Marker` si dovrà definire la propria `Location`, con coordinate e orientamento riferite all'origine degli assi del relativo `Floor` (es. angolo in alto a sinistra del piano).
        Una volta definiti i dati, possiamo istanziare un oggetto della classe `LocationProvider` passandogli la **ARView** della nostra app (necessaria visto che usamiamo tecniche di AR) e la lista dei `Marker` appena creati. Poi sull'oggetto `LocationProvider` sarà possibile registrare la nostra classe come `LocationObserver` e successivamente richiamare il metodo `start()` per far iniziare il calcolo della posizione. 
        
        - Esempio:
        ```swift
                let b1 = Building(id: "b1", name: "Casa")
                let f_1 = Floor(id: "f1_1", name: "piano terra", number: 0, building: b1, maxWidth: 5.10, maxHeight: 2.43)
                let l1 = Location(coordinates: CGPoint(x: 1.95, y: 0), heading: 0, floor: f_1)
                let l2 = Location(coordinates: CGPoint(x: 0.33, y: 0.88), heading: -0.785, floor: f_1)
                let m1 = Marker(id: "S1", image: UIImage(named: "S1")!, physicalWidth: 0.12, location: l1)
                let m2 = Marker(id: "S2", image: UIImage(named: "S2")!, physicalWidth: 0.12, location: l2)

                let locationProvider = LocationProvider(arView: arView, markers: [m1, m2])
                locationProvider.addLocationObserver(locationObserver: self)
                locationProvider.start()
        ```
        ---

    - __Creazione Statica__
        - L'utente può definire un proprio documento JSON seguendo un determinato schema ([esempio](https://github.com/tirannosario/DemoPositioningLibrary/blob/main/DemoPositioningLibrary/mydata.json) di doc JSON). (Le immagini dovranno essere comunque caricate sugli **Assets** del progetto, il JSON conterrà il riferimento al loro nome). Quindi sarà possibile istanziare un oggetto della classe `LocationProvider` passandogli la **ARView** e il nome del documento JSON. Poi sull'oggetto `LocationProvider` sarà possibile registrare la nostra classe come `LocationObserver` e successivamente richiamare il metodo `start()` per far iniziare il calcolo della posizione. 

        - Esempio:
        ```swift
            let locationProvider = LocationProvider(arView: arView, jsonName: "mydata")
            locationProvider.addLocationObserver(locationObserver: self)
            locationProvider.start()
        ```

