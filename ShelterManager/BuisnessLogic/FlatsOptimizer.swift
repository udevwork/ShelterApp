//
//  FlatsOptimizer.swift
//  ShelterManager
//
//  Created by Denis Kotelnikov on 18.02.2024.
//

import Foundation
import RealmSwift

class FlatsOptimizer {

    @ObservedRealmObject var building: Building
    
    struct Person {
        var firstName: String
        var lastName: String
    }
    
    struct Apartment: Hashable {
        var id: Int
        var capacity: Int
    }
    
    init(building: Building) {
        self.building = building
    }
    
    func distributePeopleIntoApartments(people: [Person], apartments: [Apartment]) -> ([Apartment: [Person]], [Person], [Apartment]) {
        // Группировка и сортировка семей и квартир
          let families = Dictionary(grouping: people, by: { $0.lastName })
              .mapValues { $0 }
              .values
              .sorted { $0.count > $1.count }
          
          var sortedApartments = apartments.sorted { $0.capacity < $1.capacity }
          var allocation: [Apartment: [Person]] = [:]
          var unallocatedPeople: [Person] = []
          var unusedApartments: [Apartment] = sortedApartments.map { $0 }

          // Размещение семей по размеру
          for family in families {
              if let index = sortedApartments.firstIndex(where: { $0.capacity >= family.count }) {
                  allocation[sortedApartments[index]] = family
                  sortedApartments[index].capacity -= family.count // Обновляем вместимость квартиры
                  if sortedApartments[index].capacity == 0 {
                      unusedApartments.removeAll { $0 == sortedApartments[index] }
                  }
                  sortedApartments = sortedApartments.filter { $0.capacity > 0 } // Удаляем заполненные квартиры
              } else {
                  unallocatedPeople += family
              }
          }

          // Возвращаем результаты
          return (allocation, unallocatedPeople, unusedApartments)
    }
    

    func trunc(of surname: String) -> String {
        let index = surname.index(surname.startIndex, offsetBy: min(5, surname.count), limitedBy: surname.endIndex) ?? surname.endIndex
        return String(surname[..<index])
    }
    
    func test() -> [String] {
        
        let apartments = Array( building.livingSpaces.map { room in
            Apartment(id: Int(room.number) ?? 0, capacity: Int(room.maxResident) ?? 0)
        })
        
        let people = Array(building.residents.map { user in
            Person(firstName: user.firstName, lastName: user.secondName)
        })
        
      
      
        let result = distributePeopleIntoApartments(people: people, apartments: apartments)
        
        let file = result.0.sorted {
            $0.key.capacity < $1.key.capacity
        }
        
        var results: [String] = []
        
        file.forEach { elem in
            results.append("Room №: \(elem.key.id). Capacity: \(elem.value.count)/\(elem.key.capacity)")
            elem.value.forEach { pres in
                results.append("    person: \(pres.firstName) \(pres.lastName)")
            }
        }
        

        results.append("Not allocated: ")
        
        result.1.forEach { elem in
            results.append("    person: \(elem.firstName) \(elem.lastName)")
        }
        
        results.append("Free livingspaces: ")
        result.2.forEach { elem in
            results.append("№: \(elem.id). Capacity: \(elem.capacity)")
        }
        
        return results
    }
}

