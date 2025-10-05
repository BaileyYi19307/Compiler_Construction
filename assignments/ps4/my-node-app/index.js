import express from 'express';

const app = express();

app.get('/',async(req,res)=>{
    const response = await fetch("https://www.google.ca/");
    let data = response.json();
    console.log(data);
    res.send("hello");
    //async and await

})

app.listen(3000);
console.log('Started server on port 3000');

