# creator-alliance-api

<a name="readme-top"></a>

<div align="center">
  <h3><b>Creator Alliance Api</b></h3>
</div>

<!-- TABLE OF CONTENTS -->

# 📗 Table of Contents

- [creator-alliance-api](#creator-alliance-api)
- [📗 Table of Contents](#-table-of-contents)
- [📖 Creator Alliance Api ](#-creator-alliance-api-)
  - [🛠 Built With ](#-built-with-)
    - [Tech Stack ](#tech-stack-)
  - [💻 Getting Started ](#-getting-started-)
    - [Prerequisites](#prerequisites)
    - [Setup](#setup)
    - [Run](#run)
    - [Test](#test)

<!-- PROJECT DESCRIPTION -->

# 📖 Creator Alliance Api <a name="about-project"></a>

**Creator Alliance Api** is the server application for [Creator Alliance](https://google.com/) to contribute the Creator-Sponsor society.

## 🛠 Built With <a name="built-with"></a>

### Tech Stack <a name="tech-stack"></a>

<details>
  <summary>Client</summary>
  <ul>
    <li><a href="https://react.dev/">React</a></li>
    <li><a href="https://tailwindcss.com/">TailwindCSS</a></li>
    <li><a href="https://www.typescriptlang.org/">TypeScript</a></li>
    <li><a href="https://vitejs.dev/">Vite</a></li>
  </ul>
</details>

<details>
  <summary>Server</summary>
  <ul>
    <li><a href="https://rubyonrails.org/">Ruby on Rails</a></li>
  </ul>
</details>

<details>
<summary>Database</summary>
  <ul>
    <li><a href="https://www.postgresql.org/">PostgreSQL</a></li>
  </ul>
</details>

<!-- GETTING STARTED -->

## 💻 Getting Started <a name="getting-started"></a>

To get a local copy up and running, follow these steps.

### Prerequisites

In order to run this project you need [ruby-on-rails](https://www.ruby-lang.org/en/downloads/) and [postgresql](https://www.postgresql.org/) set up on your computer:

Check your ruby and postgresql installations are complete.

```sh
  ruby --version && postgres --version
```

### Setup

Clone this repository or download as a zip file to your desired folder:

```sh
  cd my-folder
  git clone git@github.com:creator-alliance/creator-alliance-api.git
```

Enter the Root level of the project

```sh
  cd creator-alliance-api
```

Install the dependencies using yarn or npm:

```sh
> bundle install
```

Set up the database:

```sh
> rails db:setup
```

Run database migrations:

```sh
> rails db:migrate
```

### Run

run the app.

```sh
> sh run_dev.sh
```

### Test

set up rspec for once

```sh
> rails generate rspec:install
```

execute tests

```sh
> sh exec_tests.sh
```

<p align="right">(<a href="#readme-top">back to top</a>)</p>
