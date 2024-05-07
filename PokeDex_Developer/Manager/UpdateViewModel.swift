//
//  UpdateManager.swift
//  PokeDex_Developer
//
//  Created by 유영웅 on 3/26/24.
//

import Foundation
import Alamofire
import Combine

class UpdateViewModel:ObservableObject{
    
    @Published var pokemon:Pokemons? = nil
    @Published var varieties:Varieties? = nil
    @Published var pokemonList:PokemonPages? = nil
    
    @Published var query:Parameters = ["page": 1, "region": "전국", "types_1": "", "types_2": "", "query": ""]
    var cancelable = Set<AnyCancellable>()
    
    //DB저장 ==============================
    func storePokemon(num:Int)async throws -> (form : [String],chian: Int){
        let params = try await FetchParametersManager.shared.getPokemonSpecies(num: num)
        request(params: params,method: .post, endPoint: "pokemon")
        return (params["varieties"] as! [String],params["evolution_tree"] as! Int)
    }
    func storePokemonVarieties(form:String)async throws{
        let params = try await FetchParametersManager.shared.getPokemon(form: form)
        request(params: params,method: .post, endPoint: "variety")
    }
    func storePokemonEvolutionTree(num:Int)async throws{
        let params = try await FetchParametersManager.shared.getPokemonEvolution(num: num)
        request(params: params,method: .post, endPoint: "tree")
    }
    
    //DB읽기 =============================
    func fetchPokemon(num:Int) async throws{
        requestDecodable(params: nil, method: .get, endPoint: "pokemon/\(num)",encoding: JSONEncoding.default) { [weak self] (data : PokemonResponse) in
            self?.pokemon = data.data
        }
    }
    func fetchPokemons() async throws{
        requestDecodable(params: query, method: .get, endPoint: "pokemon",encoding: URLEncoding.queryString){ [weak self] (data : PokemonListResponse) in
            self?.pokemonList = data.data
        }
    }
    func fetchPokemonVarieties(form:String)async throws{
        requestDecodable(params: nil, method: .get, endPoint: "variety/\(form)",encoding: URLEncoding.queryString){ [weak self] (data : VarietiesRespons) in
            self?.varieties = data.data
        }
    }
    func fetchPokemonEvolutionTree(num:Int)async throws{
        let params = try await FetchParametersManager.shared.getPokemonEvolution(num: num)
        request(params: params,method: .post, endPoint: "tree")
    }
    
    //DB수정 =============================
    func updatePokemon(num:Int,pokemon:Pokemons)async throws{
        request(params: pokemonParameters(pokemon: pokemon),method: .patch, endPoint: "pokemon/\(num)")
    }
    func updatePokemonForm(name:String,varieties:Varieties)async throws{
        request(params: formParameters(form: varieties),method: .patch, endPoint: "variety/\(name)")
    }
    
    //DB삭제 =============================
    func deletePokemon(num:Int)async throws{
        request(params:nil, method: .delete, endPoint: "pokemon/\(num)")
    }
    func deleteForm(name:String)async throws{
        request(params:nil, method: .delete, endPoint: "pokemon/\(name)")
    }
    
    
    
    func updatePokemonInfo(num:Int) async throws{
        let pokemonSpeciesManager = PokemonSpeciesManager.shared
        //포켓몬 데이터 mongoDB에 저장
        let pokemonData =  try await storePokemon(num: num)
        
        await withThrowingTaskGroup(of: Void.self) { group in
            for form in pokemonData.form{
                group.addTask {
                    try await self.storePokemonVarieties(form: form)
                }
            }
        }
        if !(try await pokemonSpeciesManager.getEvolutionFromSpecies(num: num)){
            try await storePokemonEvolutionTree(num: pokemonData.chian)
        }
    }
    private func request(params:Parameters?,method:HTTPMethod,endPoint:String){
        AF.request("http://\(Bundle.main.infoDictionary?["LOCAL_URL"] ?? "")/\(endPoint)", method: method, parameters: params, encoding: JSONEncoding.default)
            .validate()
            .response{ response in
                switch response.result {
                case .success(let value):
                    print("Response: \(String(describing: value))")
                case .failure(let error):
                    print("Error: \(error)")
                }
            }
    }
    private func requestDecodable<T:Decodable>(params:Parameters?,method:HTTPMethod,endPoint:String,encoding:ParameterEncoding,save:@escaping ((T) -> Void)){

        AF.request("http://\(Bundle.main.infoDictionary?["LOCAL_URL"] ?? "")/\(endPoint)", method: method, parameters: params, encoding: encoding)
            .publishDecodable(type: T.self)
            .value()
            .eraseToAnyPublisher()
            .sink(receiveCompletion: ({ completion in
                switch completion{
                case .failure(let error):
                    print(error.localizedDescription)
                case .finished:
                    print(completion)
                }
            }), receiveValue: save)
            .store(in: &cancelable)
    }
    
    private func pokemonParameters(pokemon:Pokemons) -> Parameters{
        
        var dex = [[String:Any]]()
        pokemon.dex.forEach {
            let dic = ["region":$0.region,"num":$0.num]
            dex.append(dic)
        }
        return [
            "_id" : pokemon.id,
            "color" : pokemon.color,
            "base": [
                "types": pokemon.base.types,
                "image": pokemon.base.image
            ],
            "capture_rate": pokemon.captureRate,
            "dex" : dex,
            "egg_group":  pokemon.eggGroup,
            "evolution_tree": pokemon.evolutionTree,
            "forms_switchable": pokemon.formsSwitchable,
            "gender_rate": pokemon.genderRate,
            "genra": pokemon.genra,
            "hatch_counter": pokemon.hatchCounter,
            "name": pokemon.name,
            "text_entries" : [
                "text": pokemon.textEntries.text,
                "version" : pokemon.textEntries.version
            ],
            "varieties" : pokemon.varieties
        ] as Parameters
    }
    private func formParameters(form:Varieties) -> Parameters{
        
        return [
            "_id" : form.id,
            "abilites" : [
                "name" : form.abilites.name,
                "text" : form.abilites.text,
                "is_hidden" : form.abilites.isHidden,
            ],
            "form" : [
                "images" : form.form.images,
                "name" : form.form.name
            ],
            "types" : form.types,
            "height" : form.height,
            "weight" : form.weight,
            "stats" : form.stats
        ] as Parameters
    }
}



