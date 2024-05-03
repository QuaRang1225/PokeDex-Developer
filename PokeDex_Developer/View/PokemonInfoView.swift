//
//  PokemonInfoView.swift
//  PokeDex_Developer
//
//  Created by 유영웅 on 3/26/24.
//

import SwiftUI
import Kingfisher

struct PokemonInfoView: View {
    @StateObject var vm = UpdateViewModel()
    @State var firstNum = ""
    @State var lastNum = ""
    @State var num = ""
    @State var name = ""
    @State var code = ""
    
    var body: some View {
        VStack{
            title(text: "포켓몬 정보", imageLink: "https://github.com/PokeAPI/sprites/blob/master/sprites/items/poke-ball.png?raw=true")
            storePokemons
            storePokemon
            title(text: "폼 정보", imageLink: "https://github.com/PokeAPI/sprites/blob/master/sprites/items/sablenite.png?raw=true")
            storePokemonForms
            title(text: "진화 트리 정보", imageLink: "https://github.com/PokeAPI/sprites/blob/master/sprites/items/gen5/dawn-stone.png?raw=true")
            storePokemonTree
        }
        .foregroundStyle(.primary)
        .padding(.horizontal)
    }
}

#Preview {
    PokemonInfoView()
}

extension PokemonInfoView{
    func title(text:String,imageLink:String) -> some View{
        HStack{
            KFImage(URL(string: imageLink))
                .resizable()
                .frame(width: 50,height: 50)
            Text(text)
                .bold()
            Spacer()
        }
        .font(.title2)
        .padding(.top)
    }
    func updateButton(type:String,action:@escaping()->()) -> some View{
        Button(action: action) {
            Text(type)
                .padding(5)
                .padding(.horizontal)
                .background(.pink)
                .cornerRadius(10)
                .foregroundColor(.white)
                .bold()
        }
    }
    var storePokemons: some View{
        VStack(alignment: .leading){
            HStack(alignment: .bottom){
                Group{
                    TextField("시작번호",text: $firstNum)
                    Text("~")
                    TextField("끝번호",text: $lastNum)
                }
                .frame(width: 60)
                .font(.body)
                Spacer()
                
                updateButton(type: "저장"){
                    Task{
                        await withThrowingTaskGroup(of: Void.self) { group in
                            guard let first = Int(firstNum),let last = Int(lastNum) else { return }
                            for i in first...last{
                                group.addTask {
                                    try await vm.updatePokemonInfo(num: i)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    var storePokemon:some View{
        VStack(alignment: .leading){
            HStack(alignment: .bottom){
                TextField("번호",text: $num)
                    .frame(width: 60)
                    .font(.body)
                Spacer()
                updateButton(type: "저장"){
                    Task{
                        guard let num = Int(num) else {return}
                        let _ = try await vm.storePokemon(num: num)
                    }
                }
            }
        }
    }
    var storePokemonForms:some View{
        VStack(alignment: .leading){
            HStack(alignment: .bottom){
                TextField("폼이름 (영문명) ",text: $name)
                    .font(.body)
                Spacer()
                updateButton(type: "저장"){
                    Task{
                        try await vm.storePokemonVarieties(form: name)
                    }
                }
            }
        }
    }
    var storePokemonTree:some View{
        VStack(alignment: .leading){
            HStack(alignment: .bottom){
                TextField("진화 트리 코드 (숫자)",text: $code)
                    .font(.body)
                Spacer()
                updateButton(type: "저장"){
                    Task{
                        guard let code = Int(code) else {return}
                        try await vm.storePokemonEvolutionTree(num:code)
                    }
                }
            }
        }
    }
}
