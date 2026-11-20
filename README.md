# Late Deliveries and Customer Reviews: Olist E-Commerce SQL Analysis

## Business question
What causes late deliveries on Olist's marketplace, how much do they hurt customer reviews, and what should the business fix first?

## Data
- **Source:** [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) (Kaggle, CC BY-NC-SA 4.0)
- About 100,000 real, anonymised orders placed between 2016 and 2018 across 8 linked tables: orders, customers, sellers, products, order items, payments, reviews and category translations
- **Analysis window:** January 2017 to August 2018. 2016 is too sparse to use (4 orders in September, none in November), so it was excluded from the main checks.

## Tools
MySQL, MySQL Workbench, SQL (joins across 4 tables, CASE, aggregation, date functions, window functions)

## Method
1. Built a MySQL database from 8 raw CSV files (`sql/00_load_data.sql`), handling Windows line endings, multi-line review comments, blank dates and a review ID that is not unique
2. Explored the data: order status, date coverage, top categories, delivery times (`sql/01_exploration.sql`)
3. Measured how late deliveries relate to review scores
4. Broke late deliveries down by customer state, seller location and delivery stage
5. Re-checked the main findings inside the clean analysis window

## Key findings
1. **8.1% of delivered orders arrived late** (after Olist's own estimated date), about 7,800 orders.
2. **Late orders get much worse reviews:** 2.57 stars on average vs 4.29 for on-time orders. **46% of late orders received a 1-star review, compared with 6.6% of on-time orders**, about 7 times more likely. The result was unchanged when re-checked inside the January 2017 to August 2018 window.
3. **Most of the delay happens with the courier, not the seller.** Late orders took 5.8 days to reach the courier (vs 3.0 on time) but 25.7 days from courier to customer (vs 7.8). About 86% of the extra time is in the courier stage.
4. **Rio de Janeiro is the biggest problem by volume.** Northern and north-eastern states have the highest late rates (Maranhão 19.7%, Ceará 15.3%), but Rio de Janeiro produces the most late orders (about 1,670 at a 13.5% late rate), more than 10 times Maranhão (about 141).
5. **Distance matters, but it is not the whole story.** 60% of sellers are in São Paulo. Orders shipped across state lines were late 9.0% of the time vs 6.0% within the same state. Rio is next to São Paulo yet still has high delays, which points to a local logistics issue rather than distance.
6. Most orders arrive within two weeks (71%), but 4.5% take more than 30 days.

## Recommendations
1. **Review courier performance in Rio first.** Rio has the highest number of late orders (about 1,670), so fixing delivery issues there could help the largest number of customers. Rio is also close to São Paulo, where most sellers are based, so distance alone does not explain the delays. I would review courier performance and delivery agreements in Rio first, then investigate routes to the North-East, where late-delivery rates are higher.
2. **Set a target for sellers to hand over orders within 3 days.** On-time orders reach the courier in about 3 days on average. Olist could use this as a target and flag sellers who regularly take longer, so delays can be addressed before they affect delivery.
3. **Inform customers before their orders become late.** If an order has not reached the courier within 5 days, Olist could automatically send a delay notification. In some cases, it could also offer a small voucher to improve the customer experience and reduce negative reviews.

## Measuring success
Track Rio's late-delivery rate and the percentage of 1-star reviews each month after the changes, compared with the months before and with states where nothing changed. If both fall in Rio but not elsewhere, the improvements are likely working.

## Limitations
- The data does not say which courier delivered each order, so the analysis can locate the delay in the courier stage but cannot name a specific courier.
- The link between late delivery and low reviews is strong, but it is a correlation. Other factors, such as product quality from slow sellers, may also play a part.
- "Late" is measured against Olist's own estimated date, which may already be generous for some routes.
- Orders with items from sellers in several states can appear in both the "same state" and "different state" groups, so those counts overlap slightly.
- A small number of orders have more than one review.

## Repository structure
```
sql/
  00_load_data.sql      creates the database and loads the CSV files
  01_exploration.sql    exploration and analysis queries
README.md
```

## How to run
1. Download the dataset from Kaggle and unzip it into one folder
2. Place `00_load_data.sql` in the same folder
3. From that folder, run: `mysql --local-infile=1 -u root -p < 00_load_data.sql`
4. Open `01_exploration.sql` in MySQL Workbench and run the queries
