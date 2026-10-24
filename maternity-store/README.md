# Nine Moons Maternity (online store)

A starter online shop for maternity and nursing clothes. It is one file, `index.html`, with no build step.
Open it in a browser to try it.

## What it does

- Product catalogue with categories (dresses, tops, jeans, knitwear, support, swim) and a "Nursing-friendly" filter
- Filter by pregnancy stage (1st, 2nd, 3rd trimester, postpartum)
- Due-date helper: enter a due date, see the current week, and jump to clothes that fit now
- Product view with colours and sizes ("buy your pre-pregnancy size")
- Size guide (EU / UK / US, bust, bump and hip measurements)
- Bag with quantities, free-delivery progress bar and checkout form

## Change it

At the top of the `<script>` in `index.html`:

- `SHOP`: currency, free-delivery amount, delivery cost, contact email
- `PRODUCTS`: name, price, colours, sizes, stages and description of each item

The product pictures are simple drawings. Replace them with real photos when you have them.

## Before taking real orders

The checkout is a preview: it takes no payment and sends no order. To sell for real, pick one:

1. **Easiest:** move the products into a hosted shop (Shopify, Wix, or WooCommerce) that handles payment, stock, tax and shipping.
2. **Keep this page:** add Stripe Checkout or Stripe Payment Links for each product, and host the page on GitHub Pages or Netlify.

You will also need a returns policy, privacy policy, terms of sale and (in the EU) a business registration and VAT setup.
