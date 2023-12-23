package main

import (
	"bufio"
	"fmt"
	"log"
	"os"
	"strings"
)

type coord complex64

var Neighbors = []coord{1, -1, 1i, -1i}

type neighbor struct {
	Coord  coord
	Weight int
}

type simpleNeighbor struct {
	Id     int
	Weight int
}

func passable(grid [][]string, rc coord) bool {
	r, c := int(imag(rc)), int(real(rc))
	if r < 0 || c < 0 || r >= len(grid) || c >= len(grid[0]) {
		return false
	}
	return grid[r][c] != "#"
}

func passableNeighbors(grid [][]string, start coord) []coord {
	ret := make([]coord, 0, 4)
	for _, n := range Neighbors {
		if passable(grid, start+n) {
			ret = append(ret, start+n)
		}
	}
	return ret
}

func shortcut(grid [][]string, start coord) []neighbor {
	ret := make([]neighbor, 0, 4)
	for _, n := range passableNeighbors(grid, start) {
		prev, curr := start, n
		w := 1
		for neigh := passableNeighbors(grid, curr); len(neigh) == 2; neigh = passableNeighbors(grid, curr) {
			w = w + 1
			if neigh[0] == prev {
				prev, curr = curr, neigh[1]
			} else {
				prev, curr = curr, neigh[0]
			}
		}
		ret = append(ret, neighbor{Coord: curr, Weight: w})
	}
	return ret
}

func mkgraph(grid [][]string, start coord) map[coord][]neighbor {
	graph := map[coord][]neighbor{}
	closed := map[coord]bool{}
	open := []coord{start}
	for len(open) != 0 {
		curr := open[0]
		open = open[1:]
		closed[curr] = true
		graph[curr] = shortcut(grid, curr)
		for _, n := range graph[curr] {
			if !closed[n.Coord] {
				open = append(open, n.Coord)
			}
		}
	}
	return graph
}

func simplify(graph map[coord][]neighbor, start coord, end coord) [][]simpleNeighbor {
	coordMap := map[coord]int{}
	outGraph := make([][]simpleNeighbor, len(graph))
	nextIdx := 0
	getIdx := func(c coord) int {
		if _, ok := coordMap[c]; !ok {
			coordMap[c] = nextIdx
			nextIdx = nextIdx + 1
		}
		return coordMap[c]
	}
	getIdx(start)
	getIdx(end)
	for c, ns := range graph {
		outNeigh := make([]simpleNeighbor, len(ns))
		cidx := getIdx(c)
		for i, n := range ns {
			nidx := getIdx(n.Coord)
			outNeigh[i] = simpleNeighbor{Id: nidx, Weight: n.Weight}
		}
		outGraph[cidx] = outNeigh
	}
	return outGraph
}

func longestPath(graph [][]simpleNeighbor, start int, end int) int {
	pathMap := map[int]bool{}
	best := 0
	var dfs func(c int, cost int)
	dfs = func(c int, cost int) {
		if c == end {
			if best < cost {
				best = cost
			}
			return
		}
		if pathMap[c] {
			return
		}
		pathMap[c] = true
		for _, n := range graph[c] {
			dfs(n.Id, cost+n.Weight)
		}
		pathMap[c] = false
	}
	dfs(start, 0)
	return best
}

func main() {
	file, err := os.Open("23.in")
	if err != nil {
		log.Fatal(err)
	}
	defer file.Close()
	grid := [][]string{}
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		grid = append(grid, strings.Split(scanner.Text(), ""))
	}
	graph := mkgraph(grid, 1)
	end := coord(complex(float32(len(grid[0])-2), float32(len(grid)-1)))
	simpleGraph := simplify(graph, 1, end)
	fmt.Println(longestPath(simpleGraph, 0, 1))
}
