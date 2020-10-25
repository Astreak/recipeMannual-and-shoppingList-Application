import { Component, OnInit } from '@angular/core';
import { Recipe } from '../recipe.model';

@Component({
  selector: 'app-recipes-list',
  templateUrl: './recipes-list.component.html',
  styleUrls: ['./recipes-list.component.css']
})
export class RecipesListComponent implements OnInit {
  recipes: Recipe[] = [
    new Recipe("The first", "Ok this is the first entry", "https://images-gmi-pmc.edge-generalmills.com/7eb09e32-fb06-4a34-97e6-def91b62164f.jpg"),
    new Recipe("The hotdog", "Hello i love hot dogs","https://i.ndtvimg.com/i/2016-10/hot-dog-620_620x350_71476862261.jpg")
  ];
  constructor() { }

  ngOnInit(): void {
  }

}
