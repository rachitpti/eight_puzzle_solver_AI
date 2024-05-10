//
//  main.swift
//  this file has to be named 'main' so the methods in this project run at top level
//
//  Created by Rachit Prajapati on 5/6/24.
//

import Foundation  //Framework from apple that contains the basic properties and methods in Swift language.

//No priority queue pre-built implementation in Swift
//Priority Queue and heap implementation inspired from this book and code snippet
//https://www.kodeco.com/books/data-structures-algorithms-in-swift/v4.0
//https://github.com/kodecocodes/swift-algorithm-club/tree/master/Priority%20Queue
struct PriorityQueue<Element> { //generic type Element which is used as a type Int in the application
    
    var elements: [Element] //elements inside the queue
    private let priorityFunction: (Element, Element) -> Bool //function definition that sorts the ordering of elements in the queue

    init(elements: [Element] = [], priorityFunction: @escaping (Element, Element) -> Bool) {
        self.elements = elements
        self.priorityFunction = priorityFunction
        buildHeap()
    } //initializer to initialize the elements and organize them in heap based on priority function

    private mutating func buildHeap() {
        let optimalHeapCountIndex  = elements.count / 2
        
        for index in (0..<(optimalHeapCountIndex)).reversed() {
            heapifyDown(from: index)
        }
    } //constructs heap from the elements array
    
    var count: Int {
        return elements.count
    } //a computed property to fetch the count of elements inside the heap

    var isEmpty: Bool {
        elements.isEmpty
    } //computed property to check if heap is empty or not
    
    //enqueuing method
    mutating func enqueue(_ element: Element) {
        elements.append(element)
        heapifyUp(from: elements.count - 1)
    } //mutating is used because it changes the property of the struct PriorityQueue,
    //https://stackoverflow.com/questions/51128666/what-does-the-swift-mutating-keyword-mean

    //dequeuing method
    mutating func dequeue() -> Element? {
        guard !isEmpty else { return nil }
        elements.swapAt(0, elements.count - 1)
        let element = elements.removeLast() //removing the last element from the priority queue
        if !isEmpty {
            heapifyDown(from: 0) //balancing the heap
        }
        return element
    }

    //the function below is the part of the working of heap data structure
    //it moves up the element inside the heap to maintain the property of the heap
    private mutating func heapifyUp(from index: Int) {
        var childIndex = index
        let child = elements[childIndex]
        var parentIndex = (childIndex - 1) / 2

        while childIndex > 0 && priorityFunction(child, elements[parentIndex]) {
            elements[childIndex] = elements[parentIndex]
            childIndex = parentIndex
            parentIndex = (childIndex - 1) / 2
        }

        elements[childIndex] = child
    }
    //the function below is the part of the working of heap data structure
    //it moves down the element inside the heap to maintain the property of the heap after replacement/removal of the root
    private mutating func heapifyDown(from index: Int) {
        var parentIndex = index
        while true {
            
            let leftChildIndex = 2 * parentIndex + 1
            let rightChildIndex = leftChildIndex + 1
            
            var optionalSwapIndex: Int? //it only gets the value fed to it if below if statements satisfy else it remains nil (null)

            if leftChildIndex < elements.count && priorityFunction(elements[leftChildIndex], elements[parentIndex]) {
                optionalSwapIndex = leftChildIndex
            }
            if rightChildIndex < elements.count && priorityFunction(elements[rightChildIndex], elements[optionalSwapIndex ?? parentIndex]) {
                optionalSwapIndex = rightChildIndex
            }

            guard let swapIndex = optionalSwapIndex else { break }
            
            elements.swapAt(parentIndex, swapIndex)
            
            parentIndex = swapIndex
        }
    }
}

//representation of node in the graph, which represents the board, it's heuristic cost (estimated) (h(n)), it's cost for what it has covered so far (g(n))
class Node {
    var state: [Int]
    var prev_state: Node? //parent board
    var cost: Int  // g(n), cost to reach this node from the start node
    var depth: Int
    var heuristic: Int  // h(n), heuristic estimate to the goal

    init(state: [Int], parent: Node?, cost: Int, depth: Int, heuristic: Int = 0) {
        self.state = state
        self.prev_state = parent
        self.cost = cost
        self.depth = depth
        self.heuristic = heuristic
    }
}

//Custom object that contains all the elements and properties to solve the puzzle
class Problem {
    
    let goal_state = [
        1, 2, 3,
        4, 5, 6,
        7, 8, 0
    ]
    
    var nodesExpanded = 0
    var maxQueueSize = 0
    var costSoFar = [String: Int]() //storing cost with respect to the state to monitor them for handling duplicates
    var mode: Mode
    var priority_queue: PriorityQueue<Node>
    //initializer of this class which holds the mode to solve the 8 puzzle problem with respect to it
    init(mode: Mode) {
        self.mode = mode
        //below declaration is a closure, which is just a way to write a function anonymously and hold it's return value with the variable declared
        //or function declaration which sorts the elements in queue
        let make_queue = { (node1: Node, node2: Node) -> Bool in
            (node1.cost + node1.heuristic) < (node2.cost + node2.heuristic)
        }
        self.priority_queue = PriorityQueue(elements: [], priorityFunction: make_queue)
    }
    
    //Sets up the initial state for solving the puzzle. It defines a priority function for the priority queue, initializes the queue, and sets up the root node with the initial state of the puzzle.
    func aStar_search(initialState: [Int]) {
        //calls respective method based on mode selected
        let heuristic = calculateHeuristic(state: initialState)
        
        let root = Node(state: initialState, parent: nil, cost: 0, depth: 0, heuristic: heuristic)
        priority_queue.enqueue(root)
        costSoFar[stateToString(state: initialState)] = 0 //initializing cost as 0
        var explored = Set<[Int]>() //contains explored states

        
        //below loops continue to run  until there are no more nodes to explore.
        //It first dequeues the highest priority node, and checks if it's the result state -> prints the state -> and explores its successors.
        //If a successor has not been explored or already in the queue, it is enqueued.
        while !priority_queue.isEmpty {
            guard let node = priority_queue.dequeue() else { break } //fetching the node with highest priority
            
            explored.insert(node.state) //adding into explored states
            nodesExpanded += 1
            printState(node: node)
            
            if node.state == goal_state {
                print("Goal state found with solution depth \(node.depth)")
                print("Number of expanded nodes: \(nodesExpanded)")
                print("Max queue size: \(maxQueueSize)")
                return
            }
            
            let successors = expand(node: node) //fetches the successor of the node
            for successor in successors {
                let newCost = node.cost + 1
                let successorStateString = stateToString(state: successor.state)
                
                if let existingCost = costSoFar[successorStateString], existingCost <= newCost {
                    continue
                }
                
                costSoFar[successorStateString] = newCost
                priority_queue.enqueue(successor)
                maxQueueSize = max(maxQueueSize, priority_queue.count)
            }
        }
    }
    
    private func stateToString(state: [Int]) -> String {
        return state.map { String($0) }.joined(separator: ",")
    }

    //method that calculates the desired heuristic based on the mode selected by the user
    private func calculateHeuristic(state: [Int]) -> Int {
        switch mode {
        case .aStar_misplaced_tiles:
            return calculateMisplacedTiles(state: state)
        case .aStar_manhattan_dist:
            return calculateManhattanDistance(state: state)
        default:
            return 0 //ucs
        }
    }

    //misplaced tile heuristic logic
    private func calculateMisplacedTiles(state: [Int]) -> Int {
        var misplacedTiles = 0 //counts the score of misplaced tile from the goal state
        
        for index in state.indices {
            // Checking if the tile is not in the goal position and is not the empty tile
            if state[index] != goal_state[index] && state[index] != 0 {
                misplacedTiles += 1
            }
        }
        return misplacedTiles
    }
    
    //calculating manhattan distance
    private func calculateManhattanDistance(state: [Int]) -> Int {
        
        
        var manhattanDistance = 0
        var iterationCount = 0
        for index in state.indices where state[index] != 0 && state[index] != goal_state[index] {  //only looping elements whose tile value is not 0/empty and are not aligning with their goal state representation

            //fetching x,y of current tile
            let currentRow = index / 3
            let currentCol = index % 3
            
            //fetching x,y of target/destined tile by it's value
            let tileValue = state[index]
            let targetIndex = goal_state.firstIndex(of: tileValue)!
            
            let targetRow = targetIndex / 3
            let targetCol = targetIndex % 3
            
            
            manhattanDistance += abs(currentRow - targetRow) + abs(currentCol - targetCol)
            iterationCount += 1
        }
        
        return manhattanDistance
    }
    

    private func expand(node: Node) -> [Node] {
        var successors = [Node]() //holds all successive states
        let idx = node.state.firstIndex(of: 0)! //finding the empty tile by fetching it's index
        
        let row = idx / 3
        let col = idx % 3
        
        let directions = [
            (-1, 0),
            (1, 0),
            (0, -1),
            (0, 1)
        ]
        
        for (loop_row, loop_col) in directions {
            //making new position for the empty tile
            let new_Row = row + loop_row
            let new_Column = col + loop_col
            //iterating under the bounds
            if new_Row >= 0, new_Row < 3, new_Column >= 0, new_Column < 3 {
                var newState = node.state
                //creating new state and swapping the empty tile with the existing one present
                newState[idx] = newState[new_Row * 3 + new_Column]
                newState[new_Row * 3 + new_Column] = 0
                //fetching the heuristic based on the mode inputted by user
                let newHeuristic = calculateHeuristic(state: newState)
              //appending the successive node with the respective heuristic and classifying the linking of the current node as a parent node
                successors.append(Node(state: newState, parent: node, cost: node.cost + 1, depth: node.depth + 1, heuristic: newHeuristic))
            }
        }
        
        return successors
    }

    //prints the board/states
    private func printState(node: Node) {
        print("The state which is best to expand with g(n) = \(node.cost) and h(n) = \(node.heuristic)")
        let state = node.state
        print("[\(state[0]), \(state[1]), \(state[2])]")
        print("[\(state[3]), \(state[4]), \(state[5])]")
        print("[\(state[6]), \(state[7]), \(state[8])]")
    }
}

//Initializing the 8 puzzle assignment as a game.
func startGame() {
    print("""
         Let's solve the 8 puzzle, proceed to enter your puzzle. Below are some things about this game:-
                • Type 0 to present the empty tile.
                • Only enter valid 8-puzzles for best experience.
                • Enter the puzzle delimiting the numbers with a space.
                • Press ENTER/RETURN key only when done.
                • Initializing...\n
         """)

        print("Start by entering the first row: ", terminator: "")

        let puzzleRowOne = readLine()?.split(separator: " ").compactMap { Int($0) } //readline captures the output from the user
        print("Now the second row: ", terminator: "")
        let puzzleRowTwo = readLine()?.split(separator: " ").compactMap { Int($0) }
        print("And the third row: ", terminator: "")
        let puzzleRowThree = readLine()?.split(separator: " ").compactMap { Int($0) }
    
        //In Swift any data/input we receive from external source is classified into Optionals (empty value (written as 'nil') and non empty value).
        //To handle the uncertainty of the value fetched, using if-let to get the concrete non empty value
        if let rowOne = puzzleRowOne, let rowTwo = puzzleRowTwo, let rowThree = puzzleRowThree {
           
            let userPuzzle = [rowOne, rowTwo, rowThree].flatMap({ $0 })  //Inspired from :- https://stackoverflow.com/questions/24465281/flatten-an-array-of-arrays-in-swift
            //print(userPuzzle) //checking the 1d array output
            
            //check if puzzle state is valid or not, using the concept of inversion
            print("\n") //formatting
            if isValidState(userPuzzle) {
                modeSelection(userPuzzle) //proceed to mode selection
            } else {
                print("\nNo solution found. Please check your input and try again.\n")
                startGame()
            }
            print("\n") //formatting
        }
}

//using principle of inversion we check if the 8 puzzle problem is solvable or not
//referred from:- https://www.geeksforgeeks.org/check-instance-8-puzzle-solvable/#
func isValidState(_ state: [Int]) -> Bool {
    
    var inv_count = 0
    
    for i in 0..<state.count {
        for j in i+1..<state.count {
            //0 refers to the empty space
            if state[i] > 0 && state[j] > 0 && state[i] > state[j] {
                inv_count += 1
            }
        }
    }
    
    // The state is solvable if the number of inversions is even
    return inv_count % 2 == 0
}


//a typesafe approach to handle cases rather than directly using strings in Switch statement.
enum Mode {
    case uniform_cost_search
    case aStar_misplaced_tiles
    case aStar_manhattan_dist
    case none
}

func modeSelection(_ puzzle: [Int]) {
   print("""
        Just one step left before we start the game. Here are modes available in which you want to play:-
         1. Uniform Cost Search
         2. A* with the Misplaced Tile heuristic.
         3. A* with the Manhattan Distance heuristic.

         Select the mode by only typing the number. \n
        """)

    guard let modeSelected = readLine() else { return } //unwrapping an optional value using guard statement, if it's a nil (null) value then it returns else continues below with the fetched value

    let mode: Mode
    
    //classified output is of custom type Mode which will be going to be used in the functions further.
    switch modeSelected {
    case "1":
        mode = .uniform_cost_search
    case "2":
        mode = .aStar_misplaced_tiles
    case "3":
        mode = .aStar_manhattan_dist
    default:
        mode = .none
        print("Oops. Try again.")
    }
    
    initializeGameAlgorithm(withMode: mode, puzzle: puzzle) //calls all the functions with the respective mode to run the program logic
}

//instantiates the solving logic code by 1. capturing the instance representation of the initial/user inputted state and then feeding it to the solving logic.
func initializeGameAlgorithm(withMode: Mode, puzzle: [Int]) {
    //Uncomment code below to measure time
//   let startTime = Date()
    let problem = Problem(mode: withMode)
    problem.aStar_search(initialState: puzzle)
//    let endTime = Date()
    
    //since output from endTime and startTime looks like this 0.04571700096130371, thus formatting it.
    //link referenced below:- https://stackoverflow.com/questions/34929932/round-up-double-to-2-decimal-places
//    print("Time elapsed in ms is \(String(format: "%.2f", endTime.timeIntervalSince(startTime) * 1000))")
    //printing the running of timing function
    //referenced from:- https://stackoverflow.com/questions/24755558/measure-elapsed-time-in-swift
}

startGame()

